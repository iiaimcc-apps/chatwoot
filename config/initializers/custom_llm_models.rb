# frozen_string_literal: true

# Register custom LLM models for Captain that are not in ruby_llm's default registry.
Rails.application.config.after_initialize do
  require 'ruby_llm'

  custom_models = [
    { id: 'Qwen/Qwen3-32B', name: 'Qwen3-32B', family: 'Qwen', context_window: 32_768, max_output_tokens: 8192 },
    { id: 'zjuaim-stable', name: 'zjuaim-stable', family: 'zjuaim', context_window: 32_768, max_output_tokens: 8192 }
  ]

  models = RubyLLM.models.instance_variable_get(:@models)

  custom_models.each do |m|
    next if models.any? { |existing| existing.id == m[:id] }

    models << RubyLLM::Model::Info.new(
      id: m[:id],
      name: m[:name],
      provider: 'openai',
      family: m[:family],
      context_window: m[:context_window],
      max_output_tokens: m[:max_output_tokens],
      modalities: { input: ['text'], output: ['text'] },
      capabilities: ['function_calling'],
      pricing: {}
    )
    Rails.logger.info("Registered custom LLM model: #{m[:id]}")
  end
rescue StandardError => e
  Rails.logger.warn("Failed to register custom LLM models: #{e.message}")
end
