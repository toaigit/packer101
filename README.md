# packar101  
  ec2-info.sh is a shell script to get your current EC2 information that  
  you may need to give it to packer or terraform template.  
   
  patch-centos.json is a packer json file.  This packer file specifies the  
  image to be patched.  Packer with patch this image and create a new image.   
   
  nightly-patch-image.sh is a shell script you execute.   
    it will call the ec2-info.sh to get information needed,    
    update the packer json file patch-centos.json with a corrected values,   
    call "packer build new-json-file"  to build the new image.   
