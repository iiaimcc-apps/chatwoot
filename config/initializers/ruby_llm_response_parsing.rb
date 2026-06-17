# frozen_string_literal: true

require 'ruby_llm'

# RubyLLM's parse_completion_response returns nil when the API response
# lacks choices[0].message. This nil propagates to Message.new(nil) which
# calls nil.fetch(:role), raising NoMethodError: undefined method 'fetch' for nil.
#
# This patch converts any such nil-return or parsing failure into a
# RubyLLM::Error that carries the original response, so the caller can
# extract status/body/headers for debugging.
module RubyLlmResponseParsingPatch
  def parse_completion_response(response)
    result = super
    return result if result.present?

    raise RubyLLM::Error.new(response, 'The LLM API returned a response without parseable message data')
  rescue RubyLLM::Error
    raise
  rescue StandardError => e
    raise RubyLLM::Error.new(response, "Failed to parse LLM API response: #{e.message}")
  end
end

Rails.application.config.after_initialize do
  next unless defined?(RubyLLM::Providers::OpenAI)
  next if RubyLLM::Providers::OpenAI < RubyLlmResponseParsingPatch

  RubyLLM::Providers::OpenAI.prepend(RubyLlmResponseParsingPatch)
end
