#!/usr/bin/env bash
set -eu
printf 'export async function viewer() { return getServerSession(); }\n' >> app/dashboard/page.tsx
