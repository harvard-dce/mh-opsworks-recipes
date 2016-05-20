require 'serverspec'
set :backend, :exec

context 'cron_d job management' do
  describe file('/etc/cron.d/moscaler_offpeak') do
    it { should contain(' to 10 ') }
  end

  describe file('/etc/cron.d/moscaler_normal') do
    it { should contain(' to 10 ') }
  end

  describe file('/etc/cron.d/moscaler_weekend') do
    it { should contain(' to 10 ') }
  end
end
