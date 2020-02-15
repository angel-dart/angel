"use strict";

import * as vscode from "vscode";
import { workspace } from "vscode";
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
  Executable
} from "vscode-languageclient";

export function activate(context: vscode.ExtensionContext) {
  const runOpts: Executable = {
    command: "pub",
    args: ["global", "run", "jael_language_server"]
  };
  const serverOptions: ServerOptions = {
    run: runOpts,
    debug: runOpts,
    transport: TransportKind.stdio
  };
  const clientOptions: LanguageClientOptions = {
    documentSelector: [
      {
        scheme: "file",
        language: "jael"
      }
    ],
    synchronize: {
      configurationSection: "jael",
      fileEvents: workspace.createFileSystemWatcher("**/.jael")
    }
  };

  const lsp = new LanguageClient("jael", "Jael", serverOptions, clientOptions);
  context.subscriptions.push(lsp.start());
}

export function deactivate() {}
