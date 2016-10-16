# coding: utf-8
require 'ostruct'
describe "Zopa's Lending Market" do
  describe 'finding the best quote' do
    module Zopa
      class Market
        attr_reader :payment_period
        
        def initialize quote
          @payment_period = 36
          @quote = quote
        end

        def best_quote loan
          return nil if @quote['Available'] != loan
          
          OpenStruct.new(
            rate: "#{(@quote['Rate'] * 100).round(1)}%",
            requested_amount: "£#{loan}",
            monthly_repayment: "£#{monthly_payment(@quote).round(2)}",
            total_repayment: "£#{total_payment(@quote).round(2)}"
          )
        end

        def total_payment(quote)
          payment_period * monthly_payment(quote)
        end

        # The formula for the monthly payment is assumed to the exact one
        # P = Li/[1 - (1 + i)^-n]
        # (see https://en.wikipedia.org/wiki/Compound_interest)
        def monthly_payment(quote)
          monthly_interest = quote['Rate']/12

          (quote['Available'] * monthly_interest)/
            (1 - (1 + monthly_interest)**(-payment_period))
        end
      end
    end

    context 'when the market has only one quote' do
      let(:loan) { 1000 }
      let(:market) do
        Zopa::Market.new(
          { 'Lender' => 'Len', 'Rate' => 0.07, 'Available' => 1000 }
        )
      end
      
      it 'returns the loan rate offered to 1 d.p.' do
        best_quote = market.best_quote loan

        expect(best_quote.rate).to eq '7.0%'
      end

      it 'returns the loan requested' do
        best_quote = market.best_quote loan

        expect(best_quote.requested_amount).to eq '£1000'
      end

      it 'returns the total repayment to 2 d.p.' do
        best_quote = market.best_quote loan

        expect(best_quote.total_repayment).to eq '£1111.58'
      end

      it 'returns the monthly repayment to 2 d.p.' do
        best_quote = market.best_quote loan             

        expect(best_quote.monthly_repayment).to eq '£30.88'
      end
    end

    context 'when the market has one different quote' do
      let(:loan) { 1200 }
      let(:market) do
        Zopa::Market.new(
          { 'Lender' => 'Len', 'Rate' => 0.0453, 'Available' => 1200 }
        )
      end

      it 'returns the loan rate offered to 1 d.p.' do
        best_quote = market.best_quote loan

        expect(best_quote.rate).to eq '4.5%'
      end

      it 'returns the loan requested' do
        best_quote = market.best_quote loan
        
        expect(best_quote.requested_amount).to eq '£1200'
      end

      it 'returns the monthly repayment to 2 d.p.' do
        best_quote = market.best_quote loan
        
        expect(best_quote.monthly_repayment).to eq '£35.71'
      end

      it 'returns the total repayment to 2 d.p.' do
        best_quote = market.best_quote loan
        
        expect(best_quote.total_repayment).to eq '£1285.65'
      end
    end

    context 'when the one quote that is offered is insufficient' do
      it 'returns no quote' do
        loan = 1300
        market = Zopa::Market.new(
          { 'Lender' => 'Len', 'Rate' => 0.0234, 'Available' => 600 }
        )
        
        best_quote = market.best_quote loan
        
        expect(best_quote).to be_nil
      end
    end
  end
end
