# frozen_string_literal: true

require_relative "lib/this_day/app"

ThisDay::App.database # eager-load before freeze
run ThisDay::App.freeze.app
