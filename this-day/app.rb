# frozen_string_literal: true

# Lambda entry point — handler name: app.handler

require "lamby"
require_relative "lib/this_day/app"

def handler(event:, context:)
  Lamby.handler(ThisDay::App, event, context)
end
