platform :osx, '15.0'
install! 'cocoapods',
  :generate_multiple_pod_projects => true,
  :incremental_installation => true

target 'Dynamic Dark Mode' do
  use_modular_headers!
  inhibit_all_warnings!
  # Pods for Dynamic Dark Mode
  pod 'LetsMove'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
