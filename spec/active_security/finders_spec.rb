# frozen_string_literal: true

RSpec.describe ActiveSecurity::Finders do
  context "with invalid config" do
    subject(:bad_config) { ar_with_active_security }

    let(:ar_with_active_security) do
      AnonymousActiveRecord.generate(columns: ["name"]) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass

        active_security use: {finders: {default_finders: :barn_animals}}
      end
    end

    it "raises error" do
      block_is_expected.to raise_error(ActiveSecurity::InvalidConfig)
    end
  end

  context "with valid config" do
    before do
      ar_with_active_security.create(
        id: 1,
        name: "Starch"
      )
    end

    let(:ar_with_active_security) do
      AnonymousActiveRecord.generate(columns: ["name"]) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass

        active_security use: {finders: {default_finders: :restricted}}
      end
    end

    context "with no scope" do
      subject(:query_no_scope) do
        ar_with_active_security.find(1)
      end

      it "raises error" do
        block_is_expected.to raise_error(ActiveSecurity::RestrictedAccessError)
      end

      context "when not found" do
        subject(:query_no_scope) do
          ar_with_active_security.find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveSecurity::RestrictedAccessError)
        end
      end
    end

    context "with scope" do
      subject(:query_scope) do
        ar_with_active_security.where(name: "Starch").find(1)
      end

      it "does not raise error with scope" do
        block_is_expected.to not_raise_error
      end

      context "when not found" do
        subject(:query_scope) do
          ar_with_active_security.where(name: "Barney").find(2)
        end

        it "raises error with scope" do
          block_is_expected.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
