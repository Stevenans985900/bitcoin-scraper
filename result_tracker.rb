class ResultTracker

  attr_accessor :captured, :results_logger

  def initialize
    self.captured = []

    self.results_logger = Logger.new('found-bitcoins.log')
  end

  def print_summary
    ap "found #{capture.size}"
  end

  def capture(address, private_key, balance, currency)
    info = {
      address: address,
      private_key: private_key,
      amount: balance,
      currency: currency
    }

    results_logger.info(info)
    captured << info
  end
end
