class EvmhistoryController < BaseevmController
    menu_item :issuevm

    def index
        # target amount
        issue_ids = target_issue_amount(@project)
        # issues
        @issues = Issue.where(id: issue_ids).order(:start_date)
    end

    def edit
        detail_id = params[:detail_id]
        @issue = Issue.find(params[:id])
        if detail_id
            @detail = JournalDetail.find(detail_id)
        else
            journals = @issue.journals
            @histories = []
            journals.each do |journal|
                journal.details.each do |detail|
                    if detail.prop_key == 'done_ratio'
                        @histories << { detail_id: detail.id, date: journal.created_on, done_ratio: detail.value }
                    end
                end
            end
            @histories.sort_by! { |history| history[:date] }
        end
    end

    def new
        @issue = Issue.find(params[:id])
        # @details = JournalDetail.new(journal_id: 0, property: 'attr', prop_key: 'done_ratio', old_value: 0, value: 0)
    end
    
    # def show
    #     @issue = Issue.find(params[:id])
    #     @detail = JournalDetail.find(params[:detail_id])
    # end

    # def create
    #     create_ev(params[:date], params[:done_ratio])
    #     redirect_to action: :edit
    # end

    def update
        detail_id = params[:detail_id]
        issue_id = params[:issue_id]
        start_date = issue_id ? Issue.find(issue_id).start_date : nil
        end_date = issue_id ? Issue.find(issue_id).due_date : nil
        if !start_date || start_date.to_date.iso8601 > params[:date] || params[:date] > end_date.to_date.iso8601
            flash[:error] = l(:error_date)
            redirect_to action: :edit, controller: :evmhistory, id: issue_id, detail_id: detail_id
            return
        end
        if detail_id
            edit_ev(detail_id, params[:date], params[:value])
        else
            create_ev(issue_id, params[:date], params[:value])
        end
        flash[:notice] = l(:notice_successful_update)
        redirect_to action: :edit, controller: :evmhistory, id: issue_id
    end

    def destroy
        delete_ev(params[:detail_id])

        flash[:notice] = l(:notice_successful_delete)
        redirect_to action: :edit
    end

    private

    def delete_ev(detail_id, update_issue = true)
        journal_detail = JournalDetail.find(detail_id)
        journal = Journal.find(journal_detail.journal_id)
        issue = Issue.find(journal[:journalized_id])
        journal_detail.destroy
        if journal.details.empty?
            journal.destroy
        end
        if update_issue
            update_issue_done_ratio(issue.id)
        end
    end

    def create_ev(issue_id, date, value)
        issue = Issue.find(issue_id)
        journal = Journal.new(journalized_id: issue.id, journalized_type: 'Issue', user_id: User.current.id, notes: 'Manually created', created_on: date)
        journal.save
        journal_detail = JournalDetail.new(journal_id: journal.id, property: 'attr', prop_key: 'done_ratio', old_value: issue.done_ratio, value: value)
        journal_detail.save
        update_issue_done_ratio(issue.id)
    end

    def edit_ev(detail_id, date, value)
        journal_detail = JournalDetail.find(detail_id)
        issue = Issue.find(journal_detail.journal.journalized_id)
        delete_ev(detail_id, false)
        create_ev(issue.id, date, value)
    end

    def update_issue_done_ratio(id)
        issue = Issue.find(id)

        # find last journal having detail with done_ratio
        last_journal = Journal.joins(:details).where(journalized_id: issue.id).where(journalized_type: 'Issue').where('journal_details.prop_key = ?', 'done_ratio').order(created_on: :DESC).first
        if last_journal.nil?
            issue.update(done_ratio: 0)
            return
        end
        
        last_journal_detail = last_journal.details.where(prop_key: 'done_ratio').first
        
        if last_journal_detail.nil?
            issue.update(done_ratio: 0)
        else
            issue.update(done_ratio: last_journal_detail.value)
        end
    end

end