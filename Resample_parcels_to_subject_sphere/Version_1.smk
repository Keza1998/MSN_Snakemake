from functools import partial
from snakebids import bids

subjects=['SZ13']
hemis=['R', 'L']
first_path='/home/ROBARTS/kmotlana/graham/projects/ctb-akhanf/myousif9/FirstSeizure_preprocess/FirstSeizure_anatpreproc/derivatives/ciftify/'

rule all: 
    input:
        expand('/home/ROBARTS/kmotlana/kmotlana/cifti/Parcellation/sub-{subject}/{subject}_200Parcels_17Networks.pscalar.nii', subject=subjects, hemi=hemis),

rule R_gifti_to_nifti: 
    input:
        '/home/ROBARTS/kmotlana/kmotlana/cifti/Parcellation/Schaefer2018_200Parcels_17Networks_order.dlabel.nii'
    output: 
        '/home/ROBARTS/kmotlana/kmotlana/cifti/Parcellation/sub-{subject}/R_Schaefer2018_200Parcels_17Networks_order.dlabel.nii'
    shell: 
        'wb_command -cifti-separate {input} COLUMN -label CORTEX_RIGHT {output}'

rule L_gifti_to_nifti: 
    input:
        '/home/ROBARTS/kmotlana/kmotlana/cifti/Parcellation/Schaefer2018_200Parcels_17Networks_order.dlabel.nii'
    output: 
        '/home/ROBARTS/kmotlana/kmotlana/cifti/Parcellation/sub-{subject}/L_Schaefer2018_200Parcels_17Networks_order.dlabel.nii'
    shell: 
        'wb_command -cifti-separate {input} COLUMN -label CORTEX_LEFT {output}'


rule resample_labels_to_subj_sphere:
    input:
        label='/home/ROBARTS/kmotlana/kmotlana/cifti/Parcellation/sub-{subject}/{hemi}_Schaefer2018_200Parcels_17Networks_order.dlabel.nii',
        current_sphere=first_path + 'sub-{subject}/MNINonLinear/fsaverage_LR32k/sub-{subject}.{hemi}.sphere.32k_fs_LR.surf.gii',
        current_surf= first_path + 'sub-{subject}/MNINonLinear/fsaverage_LR32k/sub-{subject}.{hemi}.midthickness.32k_fs_LR.surf.gii',
        new_sphere=first_path + 'sub-{subject}/MNINonLinear/Native/sub-{subject}.{hemi}.sphere.native.surf.gii',
        new_surf=first_path + 'sub-{subject}/MNINonLinear/Native/sub-{subject}.{hemi}.midthickness.native.surf.gii',
    params:
        method="ADAP_BARY_AREA",
    output:
        '/home/ROBARTS/kmotlana/kmotlana/cifti/Parcellation/sub-{subject}/{hemi}_Native_Schaefer2018_200Parcels_17Networks_order.dlabel.nii',
    container: '/home/ROBARTS/kmotlana/connectome-workbench_latest.sif',
    threads: 8
    shell:
        "wb_command -label-resample {input.label} {input.current_sphere} {input.new_sphere} {params.method} {output} -area-surfs {input.current_surf} {input.new_surf}"


rule combining_hemisphere_dlabel_nii:
    input:
        left='/home/ROBARTS/kmotlana/kmotlana/cifti/Parcellation/sub-{subject}/L_Schaefer2018_200Parcels_17Networks_order.dlabel.nii',
        right='/home/ROBARTS/kmotlana/kmotlana/cifti/Parcellation/sub-{subject}/R_Schaefer2018_200Parcels_17Networks_order.dlabel.nii',
    output:
        '/home/ROBARTS/kmotlana/kmotlana/cifti/Parcellation/sub-{subject}/LR_Schaefer2018_200Parcels_17Networks_order.dlabel.nii',
    shell:
        'wb_command -cifti-create-label {output} -right-label {input.right} -left-label {input.left}'


rule parcellate_with_native:
    input:
        native_parcellation=rules.combining_hemisphere_dlabel_nii.output,
        subject_data= first_path + 'sub-{subject}/MNINonLinear/Native/sub-{subject}.thickness.native.dscalar.nii'
    output:
        '/home/ROBARTS/kmotlana/kmotlana/cifti/Parcellation/sub-{subject}/{subject}_200Parcels_17Networks.pscalar.nii'
    shell:
        'wb_command -cifti-parcellate {input.subject_data} {input.native_parcellation} COLUMN {output}'
