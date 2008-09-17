class DonationsController < ApplicationController
  
  # ssl_required              :new, :create
  # filter_parameter_logging  :cardNumber
  
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
    # @donation.designation                   = current_project.name
    # @donation.partnerTransactionIdentifier  = "#{current_project.id}_#{current_user.id || ''}_#{Time.now.to_i}"
    # @donation.designation                   = current_project.name
    # @donation.npoEin                        = current_project.ein
    # @donation.donorIpAddress                = request.remote_ip
    # if @donation.valid? && @donation.process

    # TODO: encapsulate this in controller or model method...
    res = Net::HTTP.post_form(URI.parse('http://qa4.networkforgood.org/PartnerDonationService/DonateService.asmx/MakeCCDonation'),
                              { 'PartnerID' => nil,
                                'PartnerPW' => nil,
                                'PartnerSource' => nil,
                                'PartnerCampaign' => nil,
                                'NpoEin' => nil,
                                'Designation' => nil,
                                'Dedication' => nil,
                                'DonorNpoDisclosure' => @donation.disclosure,
                                'DonationAmount' => @donation.amount,
                                'PartnerTransactionIdentifier' => nil,
                                'DonorIpAddress' => request.remote_ip,
                                'DonorFirstName' => @donor.first_name,
                                'DonorLastName' => @donor.last_name,
                                'DonorEmail' => @donor.email,
                                'DonorAddress1' => @donor.address1,
                                'DonorAddress2' => @donor.address2,
                                'DonorCity' => @donor.city,
                                'DonorState' => @donor.state,
                                'DonorZip' => @donor.zip,
                                'DonorPhone' => "#{@donor.phone_1}#{@donor.phone_2}#{@donor.phone_3}",
                                'CardType' => @credit_card.card_type,
                                'NameOnCard' => @credit_card.name,
                                'CardNumber' => @credit_card.number,
                                'ExpMonth' => @credit_card.expiry_date.month,
                                'ExpYear' => @credit_card.expiry_date.year,
                                'CSC' => @credit_card.csc
                              })
    puts "#{res.code} #{res.message}"
    puts res.body
    puts res.inspect


    #   @measurement = Measurement.create!(
    #     :user_id    => current_user.id, 
    #     :project_id => current_project.id,
    #     :metric_id  => Metric.donation_metric.id,
    #     :quantity   => @donation.amount
    #   )
    #   flash[:notice] = "The transaction was completed successfully. Thank you for your donation."
    #   redirect_to project_path(current_project)
    # else
    #   flash[:error] = "There was an error while processing your donation: #{@donation.error_message}" if !@donation.error_message.empty?
    #   render :action => 'new'
    # end
  end

protected 

  def load_action
    @action = Action.find(params[:social_action])
  #rescue ActiveRecord::RecordNotFound
  #  redirect_to :back
  end

end
