require 'cronjob_spec_helper'

describe Token do
  def clean_dbs
    Shift.delete_all
    AccountingDate.delete_all
    PropertiesShiftType.delete_all
    ShiftType.delete_all
  end

  describe '[51] Auto roll shift' do
    before(:each) do
      clean_dbs
      create_shift_data
      @shifts = ['morning', 'swing', 'night']

      @now = Time.now
      allow(Time).to receive(:now).and_return(@now)
    end

    it '[50.1] roll shift' do
      Shift.current(20000).roll!(nil, nil)
      expect(Shift.find(:all).length).to eq 2
      expect(Shift.current(20000).name).to eq 'swing'
      Shift.current(20000).roll!(nil, nil)
      expect(Shift.find(:all).length).to eq 3
      expect(Shift.current(20000).name).to eq 'night'
    end
  end
end
