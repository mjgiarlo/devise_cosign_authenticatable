# Thrown when a user attempts to pass a CoSign ticket that the server
# says is invalid.
class InvalidCosignTicketException < Exception
  attr_reader :ticket
  
  def initialize(ticket, msg=nil)
    super(msg)
    @ticket = ticket
  end
end
