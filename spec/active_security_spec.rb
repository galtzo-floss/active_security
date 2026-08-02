# frozen_string_literal: true

RSpec.describe ActiveSecurity do
  describe described_class::RestrictedAccessError do
    it "is a RuntimeError" do
      expect(described_class < RuntimeError).to be(true)
    end
  end

  describe described_class::UnhandledArelPredicateError do
    it "is a RuntimeError" do
      expect(described_class < RuntimeError).to be(true)
    end
  end

  describe described_class::InvalidConfig do
    it "is a RuntimeError" do
      expect(described_class < ArgumentError).to be(true)
    end
  end

  # NOTE: Default config uses :restricted, but not :finders
  context "when default config" do
    let(:records_array) do
      AnonymousActiveRecord.factory(
        columns: ["name"],
        source_data: [{id: 1, name: "Starch"}]
      ) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass
      end
    end
    let(:ar_with_active_security) do
      records_array.first.class
    end

    context "with no scope" do
      subject(:query_no_scope) do
        ar_with_active_security.find(1)
      end

      it "does not raise error" do
        block_is_expected.to not_raise_error
      end

      context "when not found" do
        subject(:query_no_scope) do
          ar_with_active_security.find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "with only restricted scope" do
      subject(:query_restricted_scope) do
        ar_with_active_security.restricted.find(1)
      end

      it "raises error" do
        block_is_expected.to raise_error(ActiveSecurity::RestrictedAccessError)
      end

      context "when not found" do
        subject(:query_restricted_scope) do
          ar_with_active_security.restricted.find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveSecurity::RestrictedAccessError)
        end
      end
    end

    context "with arbitrary scope" do
      subject(:query_scope) do
        ar_with_active_security.where(name: "Starch").find(1)
      end

      it "does not raise error" do
        block_is_expected.to not_raise_error
      end

      context "when not found" do
        subject(:query_scope) do
          ar_with_active_security.where(name: "Barney").find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "with arbitrary and restricted scope" do
      subject(:query_arbitrary_restricted_scope) do
        ar_with_active_security.where(name: "Starch").restricted.find(1)
      end

      it "does not raise error" do
        block_is_expected.to not_raise_error
      end

      context "when not found" do
        subject(:query_arbitrary_restricted_scope) do
          ar_with_active_security.where(name: "Barney").restricted.find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
