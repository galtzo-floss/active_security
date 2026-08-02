# frozen_string_literal: true

RSpec.describe ActiveSecurity::RestrictedHooks do
  before do
    ar_with_active_security.create(
      id: 1,
      name: "Starch"
    )
  end

  context "when only plugin configured" do
    let(:ar_with_active_security) do
      AnonymousActiveRecord.generate(columns: ["name"]) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass

        active_security use: :restricted
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

  context "when on_restricted_no_scope configured" do
    context "when stabby lambda" do
      let(:ar_with_active_security) do
        AnonymousActiveRecord.generate(columns: ["name"]) do
          include ActiveSecurity # rubocop:disable RSpec/DescribedClass

          active_security use: :restricted, on_restricted_no_scope: ->(config) {
            config.logger.error("Donuts are not allowed")
            raise "Shirley Temple"
          }
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
          block_is_expected.to raise_error(RuntimeError, "Shirley Temple")
        end

        it "does log" do
          output = capture(:stderr) {
            begin
              query_restricted_scope
            rescue
              nil
            end
          }
          expect(output).to include("Donuts are not allowed")
        end

        context "when not found" do
          subject(:query_restricted_scope) do
            ar_with_active_security.restricted.find(2)
          end

          it "raises error" do
            block_is_expected.to raise_error(RuntimeError, "Shirley Temple")
          end

          it "does log" do
            output = capture(:stderr) {
              begin
                query_restricted_scope
              rescue
                nil
              end
            }
            expect(output).to include("Donuts are not allowed")
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

    context "when :log" do
      let(:ar_with_active_security) do
        AnonymousActiveRecord.generate(columns: ["name"]) do
          include ActiveSecurity # rubocop:disable RSpec/DescribedClass

          active_security use: :restricted, on_restricted_no_scope: :log
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

        it "does not raise error" do
          block_is_expected.to not_raise_error
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
            block_is_expected.to raise_error(ActiveRecord::RecordNotFound)
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

    context "when :raise" do
      let(:ar_with_active_security) do
        AnonymousActiveRecord.generate(columns: ["name"]) do
          include ActiveSecurity # rubocop:disable RSpec/DescribedClass

          active_security use: :restricted, on_restricted_no_scope: :raise
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

        it "does not log" do
          output = capture(:stderr) {
            begin
              query_restricted_scope
            rescue
              nil
            end
          }
          expect(output).to eq("")
        end

        context "when not found" do
          subject(:query_restricted_scope) do
            ar_with_active_security.restricted.find(2)
          end

          it "raises error" do
            block_is_expected.to raise_error(ActiveSecurity::RestrictedAccessError)
          end

          it "does not log" do
            output = capture(:stderr) {
              begin
                query_restricted_scope
              rescue
                nil
              end
            }
            expect(output).to eq("")
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

    context "when :log_and_raise" do
      let(:ar_with_active_security) do
        AnonymousActiveRecord.generate(columns: ["name"]) do
          include ActiveSecurity # rubocop:disable RSpec/DescribedClass

          active_security use: :restricted, on_restricted_no_scope: :log_and_raise
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

    context "when invalid" do
      subject(:query) do
        ar_with_active_security.restricted.find(1)
      end

      let(:ar_with_active_security) do
        AnonymousActiveRecord.generate(columns: ["name"]) do
          include ActiveSecurity # rubocop:disable RSpec/DescribedClass

          active_security use: :restricted, on_restricted_no_scope: :bartles
        end
      end

      it "raises error" do
        block_is_expected.to raise_error(ActiveSecurity::InvalidConfig)
      end
    end
  end

  context "when finders also configured" do
    let(:ar_with_active_security) do
      AnonymousActiveRecord.generate(columns: ["name"]) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass

        active_security use: [:finders, :restricted], default_finders: :restricted
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
end
