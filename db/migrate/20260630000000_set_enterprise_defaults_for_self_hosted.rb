# frozen_string_literal: true

class SetEnterpriseDefaultsForSelfHosted < ActiveRecord::Migration[7.0]
  def up
    return unless ChatwootApp.enterprise?

    # Unlock and set plan to enterprise
    plan_config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')
    if plan_config
      plan_config.update!(value: 'enterprise', locked: false)
    else
      InstallationConfig.create!(name: 'INSTALLATION_PRICING_PLAN', value: 'enterprise', locked: false)
    end

    # Unlock and set agent quantity to 1000
    qty_config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
    if qty_config
      qty_config.update!(value: 1000, locked: false)
    else
      InstallationConfig.create!(name: 'INSTALLATION_PRICING_PLAN_QUANTITY', value: 1000, locked: false)
    end

    # Enable all enterprise features for existing accounts
    enterprise_features = %w[
      inbound_emails help_center campaigns team_management
      channel_facebook channel_email channel_instagram channel_tiktok
      captain_integration advanced_search_indexing advanced_search
      linear_integration channel_voice
      sla custom_roles csat_review_notes conversation_required_attributes
      advanced_assignment custom_tools companies
      audit_logs disable_branding saml
      captain_v1_action_classifier captain_integration_v2
      captain_document_auto_sync help_center_embedding_search
    ]

    Account.find_each do |account|
      account.enable_features!(*enterprise_features)
    end
  end

  def down
    # No-op: reverting enterprise defaults is not supported
  end
end
