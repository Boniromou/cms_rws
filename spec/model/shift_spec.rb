require 'rails_helper'

describe Shift do
  def clean_dbs
    Shift.delete_all
    AccountingDate.delete_all
    ShiftType.delete_all
    User.delete_all
  end

  describe 'Roll' do
    before(:each) do
      clean_dbs

      @today = Date.today

      @shift_type_id = ShiftType.create!(:name => 'morning').id
      ShiftType.create!(:name => 'swing')
      ShiftType.create!(:name => 'night')

      @accounting_date_id = AccountingDate.create!(:accounting_date => @today).id

      Shift.create!(:shift_type_id => @shift_type_id, :accounting_date_id => @accounting_date_id)

      @name = 10000

      @user_id = User.create!(:name => @name, :uid => 1).id

      @station_id = Station.create!(:name => 'window#1').id
    end

    after(:each) do
      clean_dbs
    end

    it 'Morning to Swing' do
      current_shift = Shift.current
      expect(current_shift.accounting_date).to eq AccountingDate.find_by_id(@accounting_date_id).accounting_date
      expect(current_shift.name).to eq ShiftType.find_by_id(@shift_type_id).name

      current_shift.roll!(@station_id, @user_id)

      new_current_shift = Shift.current
      expect(new_current_shift.accounting_date).to eq @today
      expect(new_current_shift.name).to eq 'swing'
    end

    it 'Swing to Night' do
      current_shift = Shift.current
      expect(current_shift.accounting_date).to eq AccountingDate.find_by_id(@accounting_date_id).accounting_date
      expect(current_shift.name).to eq ShiftType.find_by_id(@shift_type_id).name

      current_shift.roll!(@station_id, @user_id)
      current_shift = Shift.current
      current_shift.roll!(@station_id, @user_id)

      new_current_shift = Shift.current
      expect(new_current_shift.accounting_date).to eq @today
      expect(new_current_shift.name).to eq 'night'
    end

    it 'Night to Morning' do
      current_shift = Shift.current
      expect(current_shift.accounting_date).to eq AccountingDate.find_by_id(@accounting_date_id).accounting_date
      expect(current_shift.name).to eq ShiftType.find_by_id(@shift_type_id).name

      current_shift.roll!(@station_id, @user_id)
      current_shift = Shift.current
      current_shift.roll!(@station_id, @user_id)
      current_shift = Shift.current
      current_shift.roll!(@station_id, @user_id)

      new_current_shift = Shift.current
      expect(new_current_shift.accounting_date).to eq @today + 1
      expect(new_current_shift.name).to eq 'morning'
    end
  end

  describe 'Helper functions' do
    it 'next shift name' do
      expect(Shift.next_shift_name_by_name('morning')).to eq 'swing'
      expect(Shift.next_shift_name_by_name('swing')).to eq 'night'
      expect(Shift.next_shift_name_by_name('night')).to eq 'morning'

      expect(lambda {Shift.next_shift_name_by_name('eight')}).to raise_error
    end
  end
end
