require "active_support/core_ext/hash"
module Octogate
  module Event
    class << self
      def register_event(name, klass)
        @events ||= {}.with_indifferent_access
        @events[name] = klass
      end

      def get(name)
        @events.fetch(name) do
          raise NotRegisteredEvent.new(name)
        end
      end
    end
  end

  class NotRegisteredEvent < StandardError; end
end

require "octogate/events/push"
require "octogate/events/pull_request"
require "octogate/events/issue"
require "octogate/events/issue_comment"
require "octogate/events/pull_request_review_comment"
