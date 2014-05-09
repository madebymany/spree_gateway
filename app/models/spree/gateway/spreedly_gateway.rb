module Spree
  class Gateway::SpreedlyGateway < Gateway
    preference :login, :string
    preference :password, :string
    preference :gateway_token, :string

    def provider_class
      ActiveMerchant::Billing::SpreedlyCoreGateway
    end

    def payment_profiles_supported?
      true
    end

    def create_profile(payment)
      if payment.source.gateway_payment_profile_id.nil?
        options = {}
        options[:email] = payment.order.email
        options.merge!({ :billing_address  => payment.order.bill_address.try(:active_merchant_hash),
                        :shipping_address => payment.order.ship_address.try(:active_merchant_hash) })

        response = provider.store(payment.source, options)

        if response.success?
          #or should this be setting the  gateway_payment_profile_id
          last_4 = response.params['payment_method_last_four_digits']
          payment.source.last_digits = last_4 if last_4
          payment.source.gateway_customer_profile_id = response.params['payment_method_token']
          payment.source.save!
        else
          payment.send(:gateway_error, response.message)
        end
      end
    end

    def authorize(money, creditcard, options = {})
      payment_method = creditcard.gateway_customer_profile_id || creditcard
      provider.authorize(money, payment_method, options)
    end

    def purchase(money, creditcard, options = {})
      payment_method = creditcard.gateway_customer_profile_id || creditcard
      provider.purchase(money, payment_method, options)
    end

    def void(identifier, creditcard, options = {})
      identifier = identifier || creditcard.gateway_customer_profile_id
      provider.void(identifier, options)
    end

  end
end
