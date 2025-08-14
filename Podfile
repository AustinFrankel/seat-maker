platform :ios, '15.0'
use_frameworks! :linkage => :static
inhibit_all_warnings!

project 'TableMakerPublish.xcodeproj'

target 'TableMakerPublish' do
  pod 'Google-Mobile-Ads-SDK'
end

# Xcode 16+ sandbox blocks CocoaPods resource scripts from writing under Pods/
# Disable user script sandboxing to allow the standard CocoaPods phases to run.
post_install do |installer|
  # Apply to Pods project
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
  installer.pods_project.save

  # Apply to each user project and target
  installer.aggregate_targets.each do |agg|
    project = agg.user_project
    project.targets.each do |t|
      t.build_configurations.each do |config|
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end
    project.save
  end
end


