# frozen_string_literal: true

RSpec.describe ActiveSecurity::FinderMethods do
  before do
    ar_with_active_security.create(
      id: 1,
      name: "Starch"
    )
  end

  let(:ar_with_active_security) do
    AnonymousActiveRecord.generate(columns: ["name"]) do
      include ActiveSecurity # rubocop:disable RSpec/DescribedClass

      active_security use: {finders: {default_finders: :restricted}, scoped: {scope: :name}}
    end
  end

  context "with HomogenousIn node" do
    subject(:query_scope) do
      ar_with_active_security.where(name: ["Starch", "Banana"]).find(1)
    end

    it "does not raise error with scope" do
      block_is_expected.to not_raise_error
    end

    context "when not found" do
      subject(:query_scope) do
        ar_with_active_security.where(name: ["Barney", "Cylon"]).find(2)
      end

      it "raises error with scope" do
        block_is_expected.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
