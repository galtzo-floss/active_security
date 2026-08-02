# frozen_string_literal: true

RSpec.describe ActiveSecurity::Scoped do
  before do
    ar_with_active_security.create(
      id: 1,
      name: "Starch"
    )
  end

  context "when configured with restricted" do
    let(:ar_with_active_security) do
      AnonymousActiveRecord.generate(columns: ["name"]) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass

        active_security use: [:restricted, {scoped: {scope: :name}}]
      end
    end

    context "with no scope" do
      subject(:query_no_scope) do
        ar_with_active_security.find(1)
      end

      it "does not raise error" do
        block_is_expected.to not_raise_error
      end

      it "does not log" do
        output = capture(:stderr) { query_no_scope }
        expect(output).to eq("")
      end

      context "when not found" do
        subject(:query_no_scope) do
          ar_with_active_security.find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "does not log" do
          output = capture(:stderr) {
            begin
              query_no_scope
            rescue
              nil
            end
          }
          expect(output).to eq("")
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

      it "does log" do
        output = capture(:stderr) {
          begin
            query_restricted_scope
          rescue
            nil
          end
        }
        expect(output).to include("(ActiveRecord::Relation) does not have secure scope:")
      end

      context "when not found" do
        subject(:query_restricted_scope) do
          ar_with_active_security.restricted.find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveSecurity::RestrictedAccessError)
        end

        it "does log" do
          output = capture(:stderr) {
            begin
              query_restricted_scope
            rescue
              nil
            end
          }
          expect(output).to include("(ActiveRecord::Relation) does not have secure scope:")
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

      it "does not log" do
        output = capture(:stderr) { query_scope }
        expect(output).to eq("")
      end

      context "when not found" do
        subject(:query_scope) do
          ar_with_active_security.where(name: "Barney").find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "does not log" do
          output = capture(:stderr) {
            begin
              query_scope
            rescue
              nil
            end
          }
          expect(output).to eq("")
        end
      end
    end
  end

  context "when finders also configured" do
    let(:ar_with_active_security) do
      AnonymousActiveRecord.generate(columns: ["name"]) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass

        active_security use: [{finders: {default_finders: :restricted}}, {scoped: {scope: :name}}, :restricted]
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
        output = capture(:stderr) {
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
          output = capture(:stderr) {
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

    context "with only restricted scope" do
      subject(:query_restricted_scope) do
        ar_with_active_security.restricted.find(1)
      end

      it "raises error" do
        block_is_expected.to raise_error(ActiveSecurity::RestrictedAccessError)
      end

      it "does log" do
        output = capture(:stderr) {
          begin
            query_restricted_scope
          rescue
            nil
          end
        }
        expect(output).to include("(ActiveRecord::Relation) does not have secure scope")
      end

      context "when not found" do
        subject(:query_restricted_scope) do
          ar_with_active_security.restricted.find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveSecurity::RestrictedAccessError)
        end

        it "does log" do
          output = capture(:stderr) {
            begin
              query_restricted_scope
            rescue
              nil
            end
          }
          expect(output).to include("(ActiveRecord::Relation) does not have secure scope")
        end
      end
    end

    context "with scoped scope" do
      subject(:query_scope) do
        ar_with_active_security.where(name: "Starch").find(1)
      end

      it "does not raise error" do
        block_is_expected.to not_raise_error
      end

      it "does not log" do
        output = capture(:stderr) { query_scope }
        expect(output).to eq("")
      end

      context "when not found" do
        subject(:query_scope) do
          ar_with_active_security.where(name: "Barney").find(2)
        end

        it "raises error" do
          block_is_expected.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "does not log" do
          output = capture(:stderr) {
            begin
              query_scope
            rescue
              nil
            end
          }
          expect(output).to eq("")
        end
      end
    end
  end
end
