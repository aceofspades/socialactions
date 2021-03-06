class DonationsController < ApplicationController
  if RAILS_ENV == 'production'
    ssl_required :new, :create
  end
  
  filter_parameter_logging  :number
  before_filter             :load_action
  
  def new
    @donation = Donation.new
    @donor = Donor.new
    @credit_card = CreditCard.new
  end
  
  def create
    @donation = Donation.new(params[:donation])
    @donor = @donation.donor = Donor.new(params[:donor])
    @credit_card = @donation.credit_card = CreditCard.new(params[:credit_card])
    @donation.action = @action

    unless @donation.valid?
      return render(:action => 'new')
    end

    # TODO: encapsulate this in controller or model method...
    require 'soap/rpc/driver'
    soap = SOAP::RPC::Driver.new(DONATENOW_AUTH['API_URL'], 'http://www.networkforgood.org/partnerdonationservice', 'http://www.networkforgood.org/partnerdonationservice/MakeCCDonation')

    #soap.wiredump_file_base = "#{RAILS_ROOT}/log"
    soap.options['protocol.http.ssl_config.verify_mode'] = nil
    soap.use_default_namespace = true

    soap.add_method('MakeCCDonation',
                    "PartnerID", 
                    "PartnerPW", 
                    "PartnerSource",
                    "PartnerCampaign", 
                    "NpoEin",
                    "Designation",
                    "Dedication",
                    "DonorNpoDisclosure",
                    "DonationAmount",
                    "PartnerTransactionIdentifier",
                    "DonorIpAddress",
                    "DonorFirstName",
                    "DonorLastName",
                    "DonorEmail",
                    "DonorAddress1",
                    "DonorAddress2",
                    "DonorCity",
                    "DonorState",
                    "DonorZip",
                    "DonorPhone",
                    "CardType",
                    "NameOnCard", 
                    "CardNumber",
                    "ExpMonth",
                    "ExpYear",
                    "CSC")

    begin
      dnres = soap.MakeCCDonation(DONATENOW_AUTH['PartnerID'],
                                  DONATENOW_AUTH['PartnerPW'],
                                  DONATENOW_AUTH['PartnerSource'],
                                  DONATENOW_AUTH['PartnerCampaign'],
                                  @action.organization_ein,
                                  nil,
                                  nil,
                                  @donation.disclosure,
                                  @donation.amount,
                                  nil,
                                  request.remote_ip,
                                  @donor.first_name,
                                  @donor.last_name,
                                  @donor.email,
                                  @donor.address1,
                                  @donor.address2,
                                  @donor.city,
                                  @donor.state,
                                  @donor.zip,
                                  "#{@donor.phone_1}#{@donor.phone_2}#{@donor.phone_3}",
                                  @credit_card.card_type,
                                  @credit_card.name,
                                  @credit_card.number,
                                  @credit_card.expiry_date.month,
                                  @credit_card.expiry_date.year,
                                  @credit_card.csc)
    rescue
      RAILS_DEFAULT_LOGGER.error "ERROR: #{$!.inspect}"
      RAILS_DEFAULT_LOGGER.error "#{$!.detail}, #{$!.faultcode}"
      #puts "res: #{res}"
      #puts soap.inspect

      @donation.errors.add_to_base "There was a problem communicating with the donation processing service."
      return render(:action => 'new')
      #raise
    end

    #require 'pp'
    #pp dnres

    unless dnres['StatusCode'] == 'Success'
      if dnres['Message'].is_a?(String)
        #puts "mess: " + dnres['Message'].inspect
        @donation.errors.add_to_base dnres['Message']
      else
        #puts "ed: " + dnres['ErrorDetails'].inspect
        #puts "ed/ei: " + dnres['ErrorDetails']['ErrorInfo'].inspect
        errs = dnres['ErrorDetails']['ErrorInfo']
        errs = [errs] unless errs.respond_to?(:each)
        
        errs.each do |err|
          @donation.errors.add_to_base err['ErrData']
        end
      end
      
      return render(:action => 'new')
    end

    @chargeid = dnres['ChargeId']
  end

protected 

  def load_action
    @action = Action.find(params[:social_action])
  end

end
