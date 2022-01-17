#!/bin/bash

kubectl create namespace #{AppId}#
kubectl create namespace spinnaker
kubectl create namespace oms

kubectl create quota --hard=cpu=4,memory=8Gi --namespace=spinnaker
kubectl create quota --hard=cpu=2,memory=4Gi --namespace=oms
kubectl create quota --hard=cpu=#{AppCpuCount}#,memory=#{AppMemoryInGB}#Gi --namespace=#{AppId}#