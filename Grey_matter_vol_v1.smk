subjects=['C003', 'HC02', 'HC01', 'HCb2', 'C036', 'HCb9', 'C023', 'HCk1', 'HCb4', 'HC05', 'C030', 'C026', 'HC04', 'HC03', 'C039', 'C040', 'SZ16', 'SZ04', 'SZ03', 'SZ12', 'SZ08', 'SZ01', 'SZ10', 'SZ11', 'SZ13', 'SZ17', 'SZ02', 'SZ06', 'SZ09', 'SZ05', 'SZ14', 'SZ15']
hemis=['R', 'L']
snsx_path='/home/ROBARTS/kmotlana/graham/projects/ctb-akhanf/myousif9/snsx/output/anat_preproc/derivatives/ciftify/'
first_path='/home/ROBARTS/kmotlana/graham/projects/ctb-akhanf/myousif9/FirstSeizure_preprocess/FirstSeizure_anatpreproc/derivatives/ciftify/'

rule all:
    input:
        expand('/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.164k_fs_LR.grey_matter.dscalar.nii', subject=subjects, hemi=hemis),
        expand('/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.native.grey_matter.dscalar.nii', subject=subjects, hemi=hemis),

        expand('/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/dscalar/sub-{subject}.164k_fs_LR.grey_matter.dscalar.nii', subject=subjects, hemi=hemis),
        expand('/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/dscalar/sub-{subject}.native.grey_matter.dscalar.nii', subject=subjects, hemi=hemis),

def first_get_white_data_function(wildcards):
    if wildcards["subject"].startswith("C0"):
        white=snsx_path
    else:
        white=first_path
    return dict(
        white_data=white + 'sub-{subject}/MNINonLinear/Native/sub-{subject}.{hemi}.white.native.surf.gii'.format(subject=wildcards['subject'], hemi=wildcards['hemi'])
        )
def first_get_pial_data_function(wildcards):
    if wildcards["subject"].startswith("C0"):
        pial=snsx_path
    else:
        pial=first_path 
    return dict(
        pial_data=pial +'sub-{subject}/MNINonLinear/Native/sub-{subject}.{hemi}.pial.native.surf.gii'.format(subject=wildcards['subject'], hemi=wildcards['hemi'])
        )

rule first_measure_gmv:
    input:
        unpack(first_get_white_data_function),
        unpack(first_get_pial_data_function),
    output:
        '/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.{hemi}.native.grey_matter_volume.shape.gii'
    shell:
        'wb_command -surface-wedge-volume {input.white_data} {input.pial_data} {output}'

def second_gvm_to_native_164k_function(wildcards):
    if wildcards["subject"].startswith("C0"):
        path=snsx_path
    else:
        path=first_path
    return dict(
        current_sphere=path +'sub-{subject}/MNINonLinear/Native/sub-{subject}.{hemi}.sphere.native.surf.gii'.format(subject=wildcards['subject'], hemi=wildcards['hemi']),
        new_sphere=path +'sub-{subject}/MNINonLinear/sub-{subject}.{hemi}.sphere.164k_fs_LR.surf.gii'.format(subject=wildcards['subject'], hemi=wildcards['hemi']),
        area_surfs= path +'sub-{subject}/MNINonLinear/Native/sub-{subject}.{hemi}.midthickness.native.surf.gii'.format(subject=wildcards['subject'], hemi=wildcards['hemi']),
        midthickness=path + 'sub-{subject}/MNINonLinear/sub-{subject}.{hemi}.midthickness.164k_fs_LR.surf.gii'.format(subject=wildcards['subject'], hemi=wildcards['hemi']),
        area_surfs_1=path + 'sub-{subject}/MNINonLinear/Native/sub-{subject}.{hemi}.midthickness.native.surf.gii'.format(subject=wildcards['subject'], hemi=wildcards['hemi']),
        area_surfs_2= path+ 'sub-{subject}/MNINonLinear/sub-{subject}.{hemi}.midthickness.164k_fs_LR.surf.gii'.format(subject=wildcards['subject'], hemi=wildcards['hemi'])
        ) 

rule second_gv_native_to_164k_second:
    input:
        unpack(second_gvm_to_native_164k_function),
        second_grey_vol_data='/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.{hemi}.native.grey_matter_volume.shape.gii',
    output:
        '/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.{hemi}.164K_fs_LR.grey_matter.surfarea.shape.gii',
    shell:
        'wb_command -metric-resample {input.second_grey_vol_data} {input.current_sphere} {input.new_sphere} ADAP_BARY_AREA {output} -area-surfs {input.area_surfs_1} {input.area_surfs_2}'

rule third_164k_gvm_to_dscalar:
    input:
        third_rh_metric=expand(rules.second_gv_native_to_164k_second.output,allow_missing = True, hemi="R"),
        third_lh_metric=expand(rules.second_gv_native_to_164k_second.output,allow_missing = True, hemi="L"),
    output:
        '/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.164k_fs_LR.grey_matter.dscalar.nii'
    shell:
        'wb_command -cifti-create-dense-scalar {output} -left-metric {input.third_lh_metric} -right-metric {input.third_rh_metric}'

rule fourth_native_gvm_to_dscalar:
     input:
         fourth_rh_n_metric='/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.R.native.grey_matter_volume.shape.gii',
         fourth_lh_n_metric='/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.L.native.grey_matter_volume.shape.gii',
     output:
         '/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.native.grey_matter.dscalar.nii',
     shell:
         'wb_command -cifti-create-dense-scalar {output} -left-metric {input.fourth_lh_n_metric} -right-metric {input.fourth_rh_n_metric}'

rule native_gvm_dscalar_file: 
    input: 
        '/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.native.grey_matter.dscalar.nii'
    output: 
        '/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/dscalar/sub-{subject}.native.grey_matter.dscalar.nii'
    shell:
        'cp {input} {output}'

rule dscalar_164k_gvm:
    input: 
        '/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.164k_fs_LR.grey_matter.dscalar.nii'
    output: 
        '/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/dscalar/sub-{subject}.164k_fs_LR.grey_matter.dscalar.nii'
    shell:
        'cp {input} {output}'

