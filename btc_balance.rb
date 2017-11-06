module BTC_BALANCE
  module_function

  BTC_METHODS = [
    :bitaps,
    # :blockexplorer,
    :blockchain
  ]

  NUM_METHODS = BTC_METHODS.length
  SATOSHIS_IN_A_BTC = 100_000_000.0

  def get(address, attempts = 0)
    return 0 if too_many_attempts?(address, attempts)

    meth = BTC_METHODS[attempts % NUM_METHODS]
    $logger.info("using #{meth} on #{address}")
    result = send(meth, address)

    return result if result.is_a?(Numeric)
    return get(address, attempts + 1) if too_many_requests?(result)

    raise "unhandled result: #{result}"
  rescue => e
    ap e
    ap e.backtrace
    return 0
  end

  def bitaps(address)
    url = "https://bitaps.com/api/address/#{address}"
    result = Curl.get(url).body_str
    json = JSON.parse(result)
    balance = json['balance']
    $logger.info "#{address} has #{balance} satoshis"

    return json unless is_number?(balance)


    balance.to_f / SATOSHIS_IN_A_BTC
  end

  def blockexplorer(address)
    url = "https://blockexplorer.com/api/addr/#{address}/balance"
    result = Curl.get(url).body_str

    result.to_f
  end

  def blockchain(address)
    url = "https://blockchain.info/q/addressbalance/#{address}"
    result = Curl.get(url).body_str
    $logger.info "#{address} has #{result} satoshis"
    return result unless is_number?(result)


    result.to_f / SATOSHIS_IN_A_BTC
  end

  def is_number?(num)
    s_num = num.to_s

    num.to_f.to_s == s_num || num.to_i.to_s == s_num
  end

  def too_many_attempts?(address, attempts)
    return false if attempts < 10

    $logger.warn "Too many attempts on #{address} :-("

    true
  end

  def too_many_requests?(result)
    return true if result.include?('429 Too Many Requests') || result.include?('Maximum concurrent requests for this endpoint reached')

    json = JSON.parse(result)
    return true if json['status'].to_s == '429'

    false
  rescue => e
     return false
  end

end
