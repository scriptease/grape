# frozen_string_literal: true

require 'spec_helper'

describe Grape::DSL::Helpers do
  let!(:shared_param) do
    Module.new do
      extend Grape::API::Helpers

      params :requires_toggle_prm do
        requires :toggle_prm, type: Grape::API::Boolean
      end
    end
  end

  let(:dummy) do
    Class.new do
      include Grape::DSL::Helpers

      def self.mods
        namespace_stackable(:helpers)
      end

      def self.first_mod
        mods.first
      end
    end
  end

  let(:base) do
    boolean_param = shared_param

    Class.new(Grape::API) do
      helpers boolean_param
    end
  end

  subject { Class.new(dummy) }
  let(:proc) do
    lambda do |*|
      def test
        :test
      end
    end
  end

  describe '.helpers' do
    it 'adds a module with the given block' do
      expect(subject).to(
        receive(:namespace_stackable).with(:helpers, kind_of(Grape::DSL::Helpers::BaseHelper))
                                     .and_call_original
      )

      expect(subject).to receive(:namespace_stackable).with(:helpers).and_call_original
      subject.helpers(&proc)

      expect(subject.first_mod.instance_methods).to include(:test)
    end

    it 'uses provided modules' do
      mod = Module.new

      expect(subject).to(
        receive(:namespace_stackable).with(:helpers, kind_of(Grape::DSL::Helpers::BaseHelper))
                                     .and_call_original
                                     .exactly(2)
                                     .times
      )
      expect(subject).to receive(:namespace_stackable).with(:helpers).and_call_original
      subject.helpers(mod, &proc)

      expect(subject.first_mod).to eq mod
    end

    it 'uses many provided modules' do
      mod  = Module.new
      mod2 = Module.new
      mod3 = Module.new

      expect(subject).to(
        receive(:namespace_stackable).with(:helpers, kind_of(Grape::DSL::Helpers::BaseHelper))
                                     .and_call_original
                                     .exactly(4)
                                     .times
      )
      expect(subject).to(
        receive(:namespace_stackable).with(:helpers)
                                     .and_call_original
                                     .exactly(3)
                                     .times
      )

      subject.helpers(mod, mod2, mod3, &proc)

      expect(subject.mods).to include(mod)
      expect(subject.mods).to include(mod2)
      expect(subject.mods).to include(mod3)
    end

    context 'with an external file' do
      it 'sets Boolean as a Grape::API::Boolean' do
        subject.helpers shared_param
        expect(subject.first_mod::Boolean).to eq Grape::API::Boolean
      end
    end

    context 'in child classes' do
      it 'is available' do
        expect do
          Class.new(base) do
            params do
              use :requires_toggle_prm
            end
          end
        end.to_not raise_exception
      end
    end
  end
end
