require 'spec_helper_acceptance'
require 'json'

test_name 'Check Inspec for simp profile'

describe 'run inspec against the appropriate fixtures for simp audit profile' do

  profiles_to_validate = ['disa_stig']

  hosts.each do |host|
    profiles_to_validate.each do |profile|
      context "for profile #{profile}" do
        context "on #{host}" do
          profile_path = File.join(
                fixtures_path,
                'inspec_profiles',
                "#{fact_on(host, 'os.name')}-#{fact_on(host, 'os.release.major')}-#{profile}"
              )

          unless File.exist?(profile_path)
            it 'should run inspec' do
              skip("No matching profile available at #{profile_path}")
            end
          else
            before(:all) do
              Simp::BeakerHelpers::Inspec.enable_repo_on(hosts)
              @inspec = Simp::BeakerHelpers::Inspec.new(host, profile)
              @inspec_report = {:data => nil}
            end

            it 'should run inspec' do
              @inspec.run
            end

            it 'should have an inspec report' do
              @inspec_report[:data] = @inspec.process_inspec_results

              info = [
                'Results:',
                "  * Passed: #{@inspec_report[:data][:passed]}",
                "  * Failed: #{@inspec_report[:data][:failed]}",
                "  * Skipped: #{@inspec_report[:data][:skipped]}"
              ]

              puts info.join("\n")

              @inspec.write_report(@inspec_report[:data])
            end

            it 'should have run some tests' do
              expect(@inspec_report[:data][:failed] + @inspec_report[:data][:passed]).to be > 0
            end

            it 'should not have any failing tests' do
              if @inspec_report[:data][:failed] > 0
                puts @inspec_report[:data][:report]
              end

              expect( @inspec_report[:data][:failed] ).to eq(0)
            end
          end
        end
      end
    end
  end
end
