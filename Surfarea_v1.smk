subjects=['C003', 'HC02', 'HC01', 'HCb2', 'C036', 'HCb9', 'C023', 'HCk1', 'HCb4', 'HC05', 'C030', 'C026', 'HC04', 'HC03', 'C039', 'C040', 'SZ16', 'SZ04', 'SZ03', 'SZ12', 'SZ08', 'SZ01', 'SZ10', 'SZ11', 'SZ13', 'SZ17', 'SZ02', 'SZ06', 'SZ09', 'SZ05', 'SZ14', 'SZ15']
subfolder= '/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data'
hemis=['R', 'L']
snsx_path='/home/ROBARTS/kmotlana/graham/projects/ctb-akhanf/myousif9/snsx/output/anat_preproc/derivatives/ciftify/'
first_path='/home/ROBARTS/kmotlana/graham/projects/ctb-akhanf/myousif9/FirstSeizure_preprocess/FirstSeizure_anatpreproc/derivatives/ciftify/'

rule all:
    input: 
        expand('/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.164K_fsLR.surfarea.dscalar.nii', subject=subjects, hemi=hemis),
        expand('/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/dscalar/sub-{subject}.164K_fsLR.surfarea.dscalar.nii', subject=subjects, hemi=hemis),
        expand('/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.native.surfarea.dscalar.nii', subject=subjects, hemi=hemis),
        expand('/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/dscalar/sub-{subject}.native.surfarea.dscalar.nii', subject=subjects, hemi=hemis),

def first_get_midthickness_data_function(wildcards):
    if wildcards["subject"].startswith("C0"):
        paths=snsx_path
    else:
        paths= first_path
    return dict(
        path_to_use=paths + 'sub-{subject}/MNINonLinear/Native/sub-{subject}.{hemi}.midthickness.native.surf.gii'.format(subject=wildcards['subject'], hemi=wildcards['hemi'])
        )

rule first_raw_to_surfarea:
    input:
        unpack(first_get_midthickness_data_function),
    output:
        '/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.{hemi}.native.surfarea.shape.gii'
    shell:
        'wb_command -surface-vertex-areas {input.path_to_use} {output}'

def second_surfarea_native_to_164k_function(wildcards):
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
rule second_surfarea_164k_to_native:
    input:
        unpack(second_surfarea_native_to_164k_function),
        second_surfarea_raw_data='/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.{hemi}.native.surfarea.shape.gii'
    output:
        '/home/ROBARTS/kmotlana/kmotlana/Final_MSN_Data/{subject}/sub-{subject}.{hemi}.164K_fs_LR.surfarea.shape.gii'
    shell:
        'wb_command -metric-resample {input.second_surfarea_raw_data} {input.current_sphere} {input.new_sphere} ADAP_BARY_AREA {output} -area-surfs {input.area_surfs} {input.midthickness}'


rule third_surfarea_164k_to_dscalar:
    input:
        third_rh_metric=expand(rules.second_surfarea_164k_to_native.output,allow_missing = True,hemi=["R"]),
        third_lh_metric=expand(rules.second_surfarea_164k_to_native.output,allow_missing = True, hemi=["L"]),
    output:
        '{subfolder}/{subject}/sub-{subject}.164K_fsLR.surfarea.dscalar.nii'
    shell:
        'wb_command -cifti-create-dense-scalar {output} -left-metric {input.third_lh_metric} -right-metric {input.third_rh_metric}'


rule fourth_surfarea_native_to_dscalar:
    input:
        fourth_lh_metric=expand(rules.first_raw_to_surfarea.output,allow_missing = True,hemi=["L"]),
        fourth_rh_metric=expand(rules.first_raw_to_surfarea.output,allow_missing = True, hemi=["R"]),
    output:
        '{subfolder}/{subject}/sub-{subject}.native.surfarea.dscalar.nii'

    shell:
        'wb_command -cifti-create-dense-scalar {output} -left-metric {input.fourth_lh_metric} -right-metric {input.fourth_rh_metric}'

rule native_dscalar_file: 
    input: 
        '{subfolder}/{subject}/sub-{subject}.native.surfarea.dscalar.nii'
    output: 
        '{subfolder}/{subject}/dscalar/sub-{subject}.native.surfarea.dscalar.nii'
    shell:
        'cp {input} {output}'

rule dscalar_164k_surfarea:
    input: 
        '{subfolder}/{subject}/sub-{subject}.164K_fsLR.surfarea.dscalar.nii'
    output: 
        '{subfolder}/{subject}/dscalar/sub-{subject}.164K_fsLR.surfarea.dscalar.nii'
    shell:
        'cp {input} {output}'