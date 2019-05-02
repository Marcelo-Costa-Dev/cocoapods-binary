require_relative 'tool/tool'

# # BACKGROUND
#
# ## ABOUT NAMES
#
# There are many kinds of name in cocoapods. Two main names are widely used in this plugin:
#
# - root_spec.name (spec.root_name, target.pod_name):
#   aka "pod_name"
#   the name we use in podfile. the concept.
#
# - target.name:
#   aka "target_name"
#   the name of the final target in xcode project. The final real thing.
#
# One pod may have multiple targets in xcode project, due to one pod can be used in multiple
# platform simultaneously. So one `root_spec.name` may have multiple corresponding `target.name`s.
# Therefore, map a spec to/from targets is a little complicated. It's one to many relation (spec -> targets).
#
# Despite the multiple platform, there's another situation to have multiple target, subspec.
# If 2 targets of same platform in podfile all have Pod A, one have 'A/sub1', 'A/sub2', the other
# have 'A/sub1', there will be 2 pod targets in Pod.xcodeproj: A-sub1-sub2, A-sub1
#
#
# # OUR RULES
#
# For simplicity, we have set several rules:
#
# 1. Any part of the pod is set to binary, all the pod should be binary
# 2. Dependencies of a binary is also binary be default, except disabled explicitly.
# 3. Don't support for the different subspec lead to multiple pod targets case.
#
#  For the first rule, for example, a subspec is binary while others are not, or in one target is
#  binary while in another is not. All the source code in this pod should be binary)
#
#  For the rule 3, it's a limitation. Solving it is not deserved as subspecs may contain duplicated
#  contents. It may happens when
#
#


module Pod
    class Prebuild

        # This class provides core data flow manipulations, illustrating
        # how 'pod_name', 'target' and 'spec' transfer between each other.
        #
        # We just process the model data here, no real action.
        class DataFlow

            include Singleton


            ################ 1 filter the podfile for prebuild  ################

            # Filter the dependencies pod in podfile, only keep the prebuilt.
            # This method return a Proc, which can be use to modify the podfile
            #
            # @param [Podfile] podfile
            # @return [Proc(String(pod_name) -> Bool)]
            def pods_filter_strategy(podfile)

                # We do use this filter method, rather than just hack the pod function,
                # because the latter can not handle subspec of different binary state.

                target_definitions = podfile.target_definition_list

                all_explicit_pod_names = target_definitions.map do |td|
                    td.prebuild_framework_pod_names(inherent_parent: false)
                end.flatten

                all_explicit_pod_names = Set.new(all_explicit_pod_names + (@missing_names||[]) )

                # # get all dependencies
                # # keep in the podfile
                # dependency_pod_names = target_definitions.map do |td|
                #     td.prebuild_framework_pod_names(inherent_parent: false)
                # end.flatten

                return Proc.new do |pod_name|
                    all_explicit_pod_names.include? pod_name
                end

            end


            # Get the prebuild targets, which will be transformed to binary framework finally.
            # (It doesn't means the target will actually perform a build action, as there may be a cache.)
            #
            # @param [Podfile] podfile
            # @param [Array<PodTargets>] pod_targets_in_prebuild_project
            #        The pod_targets of prebuild project, which have been filtered by `podfile_dependency_filter_strategy`.
            #        It should contain the targets to prebuild and it's dependencies.
            #
            # @return [Array<PodTarget>]
            def get_prebuild_targets(podfile, pod_targets_in_prebuild_project)

                target_definitions = podfile.target_definition_list

                all_explicit_pod_names = Set.new(target_definitions.map do |td|
                    td.prebuild_framework_pod_names(inherent_parent: false)
                end.flatten)

                explicitly_disabled_pod_names = Set.new(target_definitions.map do |td|
                    td.should_not_prebuild_framework_pod_names(inherent_parent: false)
                end.flatten)

                explicitly_disabled_pod_names -= all_explicit_pod_names

                return pod_targets_in_prebuild_project.reject do |target|
                    explicitly_disabled_pod_names.include?(target.pod_name) || target.specs.any?{|s| s.root.local?}
                end
            end


            ################ 2 generating project and build  ###################

            def check_
                assert @dependencies_of_original_podfile != nil
                explicity_dependecies_pod_names = @dependencies_of_original_podfile.map(&:root_name)
                filter_method = Prebuild::DataFlow.instance.pods_filter_strategy(podfile)
                ignored_pod_names = Set.new explicity_dependecies_pod_names.reject(&filter_method)

                real_generated_pod_names = Set.new self.pod_targets.map(&:pod_name).uniq

                missing_requirements = ignored_pod_names.intersection(real_generated_pod_names)
                missing_requirements.to_a
            end

            def supply_missing_names(pod_names)
                @missing_names = pod_names
            end

            # saved all the prebuilt pod names here
            # @return [Array<String>]
            attr_accessor :prebuilt_pod_names

            # saved all the prebuilt target names
            # @return [Array<String>]
            attr_accessor :prebuild_target_names

            # @param [Array<PodTarget>] pod_targets
            # @return [Void]
            def save_prebuilt_names(pod_targets)
                prebuilt_pod_names = pod_targets.map(&pod_name).uniq
            end


            ################ 3 output frameworks ##############################

            class TargetPersistenceInfo
                # meta info
                attr_accessor :target_name             # [String]
                attr_accessor :additional_info         # [TargetAdditionalInfo]

                # paths
                attr_accessor :persistence_root_folder # [Pathname]
                attr_accessor :framework_file_path     # [Pathname]
                attr_accessor :other_resources_folder  # [Pathname]
                attr_accessor :additional_info_path    # [Pathname]
            end

            class TargetAdditionalInfo
                attr_accessor :target_name            # [String]
                attr_accessor :corresponding_pod_name # [String]
                attr_accessor :target_identifier      # TODO
            end

            # Generate the persistence meta info for a target, which will be
            # used in saving framework.
            #
            # @param [PodTarget] target
            # @return [TargetPersistenceInfo]
            def persistence_info_for_target(target)

            end


            ########### 4 install built frameworks (Integration Stage) #####

            # Get all the prebuilt targets saved in the Pod/_Prebuild folder
            #
            # @return [Array<TargetPersistenceInfo>]
            def prebuilt_targets_infos

            end


            ################ 5 modify specs ################################

            class SpecModification
                attr_accessor :spec
                attr_accessor :framework_path
                attr_accessor :framework_path_by_platform
            end

            # Generate the meta info for modify specs
            #
            # @param [Array<Specification>] all_specs
            # @return [Array<SpecModification>]
            def get_spec_modification_infos(all_specs)

            end



        end
    end
end