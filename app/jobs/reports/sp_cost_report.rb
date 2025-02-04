require 'identity/hostdata'

module Reports
  class SpCostReport < BaseReport
    REPORT_NAME = 'sp-cost-report'.freeze

    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      total_limit: 1,
      key: -> { "#{REPORT_NAME}-#{arguments.first}" },
    )

    def perform(_date)
      results = transaction_with_timeout do
        Db::SpCost::SpCostSummary.call(first_of_this_month, end_of_today)
      end
      save_report(REPORT_NAME, results.to_json, extension: 'json')
    end
  end
end
