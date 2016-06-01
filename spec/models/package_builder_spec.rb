require 'spec_helper'

describe Spree::Calculator::Weight do
  def build_content_items(variant, quantity, order)
    Array.new(quantity) { |_i| Spree::Stock::ContentItem.new(build_inventory_unit(variant, order)) }
  end

  def build_inventory_unit(variant, order)
    build(:inventory_unit, variant: variant, order: order)
  end

  let(:address) { FactoryGirl.create(:address) }
  let(:order) { build(:order, ship_address: address) }

  let(:shipping_calculator) { Spree::Calculator::Shipping::ActiveShipping::BogusCalculator.new }
  let(:package_builder) { Spree::Calculator::Weight::PackageBuilder.new(shipping_calculator) }

  let(:product_package) { mock_model(Spree::ProductPackage, length: 12, width: 24, height: 47, weight: 36) }

  let(:product_with_packages) do
    build(
      :variant,
      weight: 29.0,
      product: build(
        :product,
        product_packages: [product_package]
      )
    )
  end

  let(:package) do
    double(Spree::Stock::Package,
           order: order,
           contents: [build_content_items(product_with_packages, 10, order),
                      build_content_items(product_with_packages, 4, order)].flatten)
  end

  describe 'process' do
    let(:legacy_package) { shipping_calculator.send :packages, package }

    subject { package_builder.process(package) }

    it 'compute the the same weight as the ActiveShipping::Base.packages method' do
      expect(subject.map { |package| package.weight.amount }).to eq legacy_package.map { |package| package.weight.amount }
    end

    it 'use the same weight unit as the ActiveShipping::Base.packages method' do
      expect(subject.map { |package| package.weight.unit }).to eq legacy_package.map { |package| package.weight.unit }
    end
  end
end
