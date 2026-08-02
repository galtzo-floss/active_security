# frozen_string_literal: true

RSpec.describe ActiveSecurity::Base do
  context "when using defaults" do
    before do
      ar_with_active_security.create(
        id: 1,
        name: "Starch"
      )
    end

    let(:ar_with_active_security) do
      AnonymousActiveRecord.generate(columns: ["name"]) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass

        active_security
      end
    end

    context "with no scope" do
      subject(:query_no_scope) do
        ar_with_active_security.find(1)
      end

      it "does not raise error with no scope" do
        block_is_expected.to not_raise_error
      end

      context "when not found" do
        subject(:query_no_scope) do
          ar_with_active_security.find(2)
        end

        it "raises error with no scope" do
          block_is_expected.to raise_error(ActiveRecord::RecordNotFound)
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

  context "when using restricted finders" do
    before do
      ActiveSecurity.defaults do |config|
        config.use :finders do |finders_config|
          finders_config.default_finders = :restricted
        end
      end
      ar_with_active_security.create(
        id: 1,
        name: "Starch"
      )
    end

    let(:ar_with_active_security) do
      AnonymousActiveRecord.generate(columns: ["name"]) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass

        active_security
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
  end

  context "when using config bloick" do
    before do
      ActiveSecurity.defaults do |config|
        config.use :finders do |finders_config|
          finders_config.default_finders = :restricted
        end
      end
      ar_with_active_security.create(
        id: 1,
        name: "Starch"
      )
    end

    let(:ar_with_active_security) do
      AnonymousActiveRecord.generate(columns: ["name"]) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass

        active_security use: {scoped: {scope: :name}} do |config|
          config.logger = Logger.new($stdout)
        end
      end
    end

    context "with no scope" do
      subject(:query_no_scope) do
        ar_with_active_security.find(1)
      end

      it "raises error" do
        block_is_expected.to raise_error(ActiveSecurity::RestrictedAccessError)
      end

      it "does log" do
        output = capture(:stdout) {
          begin
            query_no_scope
          rescue
            nil
          end
        }
        expect(output).to match(/\(\w*\) does not have secure scope/)
      end

      context "when not found" do
        subject(:query_no_scope) do
          ar_with_active_security.find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveSecurity::RestrictedAccessError)
        end

        it "does log" do
          output = capture(:stdout) {
            begin
              query_no_scope
            rescue
              nil
            end
          }
          expect(output).to match(/\(\w*\) does not have secure scope/)
        end
      end
    end

    context "with scope" do
      subject(:query_scope) do
        ar_with_active_security.where(name: "Starch").find(1)
      end

      it "does not raise error" do
        block_is_expected.to not_raise_error
      end

      it "does not log" do
        output = capture(:stdout) { query_scope }
        expect(output).not_to include("secure scope")
      end

      context "when not found" do
        subject(:query_scope) do
          ar_with_active_security.where(name: "Barney").find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "does not log" do
          output = capture(:stdout) {
            begin
              query_scope
            rescue
              nil
            end
          }
          expect(output).not_to include("secure scope")
        end
      end
    end
  end
end
