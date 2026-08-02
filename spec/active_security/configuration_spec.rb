# frozen_string_literal: true

RSpec.describe ActiveSecurity::Configuration do
  context "with invalid config" do
    subject(:bad_config) { ar_with_active_security }

    let(:ar_with_active_security) do
      AnonymousActiveRecord.generate(columns: ["name"]) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass

        active_security use: 1
      end
    end

    it "raises error" do
      block_is_expected.to raise_error(ActiveSecurity::InvalidConfig)
    end
  end

  context "with valid config" do
    subject(:query_privileged_scope) do
      ar_with_active_security.privileged.find(1)
    end

    before do
      ar_with_active_security.create(
        id: 1,
        name: "Starch"
      )
    end

    let(:ar_with_active_security) do
      AnonymousActiveRecord.generate(columns: ["name"]) do
        include ActiveSecurity # rubocop:disable RSpec/DescribedClass

        active_security use: {privileged: {}, finders: {default_finders: :restricted}, scoped: {scope: :name}}
      end
    end

    it "does not raise error" do
      block_is_expected.to not_raise_error
    end

    it "sets model_class" do
      expect(ar_with_active_security.active_security_config.model_class.to_s).to include("Anon")
    end
  end
end
