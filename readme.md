# Uni-verse production

This repo is qhere Uni-Verse's production environment is defined.

## Kubernetes

Initially, Uni-verse was meant to run on kubernetes. The configurations were kept for legacy reasons.

## Nix

Uni-verse is now hosted on a NixOS server, using a flake system module that can be imported and used in any NixOS server.

Using this technology allows for a fine grained control over how uni-verse could be distributed, without complicating the process of scaling it up if needed.
