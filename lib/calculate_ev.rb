require "base_calculate"

# Calculation EVM module
module CalculateEvmLogic
  # Calculation EV class.
  # EV calculate estimate time of finished issue
  #
  class CalculateEv < BaseCalculateEvm
    # min date of spent time (exclude basis date)
    attr_reader :min_date
    # max date of spent time (exclude basis date)
    attr_reader :max_date
    # daily EV
    attr_reader :daily_ev
    # cumulative EV by date
    attr_reader :cumulative_ev

    # Constractor
    #
    # @param [date] basis_date basis date.
    # @param [issue] issues culculation of EV.
    def initialize(basis_date, issues)
      # basis date
      @basis_date = basis_date
      # daily EV
      @daily_ev = calculate_earned_value issues, basis_date
      # minimum start date
      # if no data, set basis date
      @min_date = @daily_ev.keys.min || @basis_date
      # maximum due date
      # if no data, set basis date
      @max_date = @daily_ev.keys.max || @basis_date
      # basis date
      @daily_ev[@basis_date] ||= 0.0
      # addup EV
      @cumulative_ev = sort_and_sum_evm_hash @daily_ev
      @cumulative_ev.reject! { |k, _v| @basis_date < k }
    end

    # Today"s earned value
    #
    # @return [Numeric] EV value on basis date
    def today_value
      @cumulative_ev[@basis_date]
    end

    # State
    #
    # @param [CalculatePv] pv_baseline CalculatePv object
    # @return [Numeric] EV value on basis date
    def state(pv_baseline = nil)
      check_state(pv_baseline)
    end

    private

    # Calculate EV.
    # Closed date or Date of ratio was set.
    #
    # @param [issue] issues target issues of EVM
    # @param [date] basis_date basis date of option
    # @return [hash] EV hash. Key:Date, Value:EV of each days
    def calculate_earned_value(issues, basis_date)
      temp_ev = {}
      @finished_issue_count = 0
      @issue_count = 0
      if issues.present?
        issues.each do |issue|
          # closed issue
          if issue.closed?
            closed_date = issue.closed_on || issue.updated_on
            dt = closed_date.to_time.to_date
            temp_ev[dt] = add_hash_value temp_ev[dt], issue.estimated_hours.to_f
            @finished_issue_count += 1
          # progress issue
          elsif issue.done_ratio.positive?
            # latest date of changed ratio
            journals = Journal.where(journalized_id: issue.id, journal_details: { prop_key: "done_ratio" }).
                               where("created_on <= ?", basis_date.end_of_day).
                               joins(:details).
                               order(created_on: :DESC).first
            # calcurate done hours
            if journals.present?
              ratio_date = journals.created_on.to_time.to_date
              done_ratio = journals.details.first.value.to_i
              hours = issue.estimated_hours.to_f * done_ratio / 100.0
              temp_ev[ratio_date] = add_hash_value temp_ev[ratio_date], hours
            end
          end
          @issue_count += 1
        end
      end
      temp_ev
    end

    # state on basis date
    #
    # @param [CalculatePv] pv_baseline CalculatePv object
    # @return [String] state of project
    def check_state(pv_baseline = nil)
      return :no_work if @issue_count.zero?

      if pv_baseline.present?
        return :finished if pv_baseline.bac <= @cumulative_ev[@basis_date]
      else
        return :progress if @basis_date < @max_date
        return :finished if @finished_issue_count == @issue_count
      end
      :progress
    end
  end
end
