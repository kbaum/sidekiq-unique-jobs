require 'spec_helper'

module SidekiqUniqueJobs
  module Middleware
    module Server
      describe UniqueJobs do
        describe '#unlock_order_configured?' do
          context "when class isn't a Sidekiq::Worker" do
            it "returns false" do
              expect(subject.unlock_order_configured?(Class))
                .to eq(false)
            end
          end

          context "when get_sidekiq_options[:unique_unlock_order] is nil" do
            it "returns false" do
              expect(subject.unlock_order_configured?(MyWorker))
                .to eq(false)
            end
          end

          it "returns true when unique_unlock_order has been set" do
            UniqueWorker.sidekiq_options unique_unlock_order: :before_yield
            expect(subject.unlock_order_configured?(UniqueWorker))
              .to eq(true)
          end
        end

        describe '#set_unlock_order' do
          context "when worker has specified unique_unlock_order" do
            it "changes unlock_order to the configured value" do
              UniqueWorker.sidekiq_options unique_unlock_order: :before_yield
              expect do
                subject.set_unlock_order(UniqueWorker)
              end.to change { subject.unlock_order }.to :before_yield
            end
          end

          context "when worker hasn't specified unique_unlock_order" do
            it "falls back to configured default_unlock_order" do
              SidekiqUniqueJobs::Config.default_unlock_order = :before_yield
              expect do
                subject.set_unlock_order(UniqueWorker)
              end.to change { subject.unlock_order }.to :before_yield
            end
          end
        end

        describe '#before_yield?' do
          it "returns unlock_order == :before_yield" do
            allow(subject).to receive(:unlock_order).and_return(:after_yield)
            expect(subject.before_yield?).to eq(false)

            allow(subject).to receive(:unlock_order).and_return(:before_yield)
            expect(subject.before_yield?).to eq(true)
          end
        end

        describe '#after_yield?' do
          it "returns unlock_order == :before_yield" do
            allow(subject).to receive(:unlock_order).and_return(:before_yield)
            expect(subject.after_yield?).to eq(false)

            allow(subject).to receive(:unlock_order).and_return(:after_yield)
            expect(subject.after_yield?).to eq(true)
          end
        end

        describe '#default_unlock_order' do
          it 'returns the default value from config' do
            SidekiqUniqueJobs::Config.default_unlock_order = :before_yield
            expect(subject.default_unlock_order).to eq(:before_yield)

            SidekiqUniqueJobs::Config.default_unlock_order = :after_yield
            expect(subject.default_unlock_order).to eq(:after_yield)
          end
        end
      end
    end
  end
end