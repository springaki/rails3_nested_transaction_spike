require 'rails_helper'

describe Question, :type => :model do

  describe "シンプルなトランザクションの場合" do

    example "普通の書き方でロールバックされる" do
      begin
        ActiveRecord::Base.transaction do
          Question.create
          raise ActiveRecord::Rollback
        end
      rescue
        raise # ココには入りません
      end
      expect(Question.count).to eq 0
    end

  end


  describe "入れ子のトランザクションの場合" do

    example "普通の書き方だとすべてロールバックされない" do
      begin
        ActiveRecord::Base.transaction do
          Question.create
          ActiveRecord::Base.transaction do
            Question.create
            raise ActiveRecord::Rollback
          end
        end
      rescue
        raise # ココには入りません
      end
      expect(Question.count).to eq 2
    end

    example "すべてロールバックされる" do
      passed_rescue = false
      begin
        ActiveRecord::Base.transaction do
          Question.create
          ActiveRecord::Base.transaction do
            Question.create
            raise
          end
        end
      rescue
        passed_rescue = true
      end
      expect(passed_rescue).to be_truthy
      expect(Question.count).to eq 0
    end

    example "requires_new を付けて raise すると savepoint 無視してすべてロールバックされる" do
      passed_rescue = false
      begin
        ActiveRecord::Base.transaction do
          Question.create
          ActiveRecord::Base.transaction(requires_new: true) do
            Question.create
            raise
          end
        end
      rescue
        passed_rescue = true
      end
      expect(passed_rescue).to be_truthy
      expect(Question.count).to eq 0
    end

    example "requires_new を付けて raise ActiveRecord::Rollback すると想定通り内側だけロールバックされる" do
      begin
        ActiveRecord::Base.transaction do
          Question.create
          ActiveRecord::Base.transaction(requires_new: true) do
            Question.create
            raise ActiveRecord::Rollback
          end
        end
      rescue
        raise # ココには入りません
      end
      expect(Question.count).to eq 1
    end

  end

end
