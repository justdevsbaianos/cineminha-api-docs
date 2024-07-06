<script setup lang="ts">
import { ApiReference } from '@scalar/api-reference';
import '@scalar/api-reference/style.css';

const props = defineProps<{ baseUrl: string }>();
</script>

<template>
  <ApiReference :configuration="{
    spec: {
      url: `${props.baseUrl}/api-docs-output/@typespec/openapi3/openapi.yaml`,
    },
  }" />
</template>
