/********************************************************************************
 * Copyright (c) 2017-2018 TypeFox and others.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the Eclipse
 * Public License v. 2.0 are satisfied: GNU General Public License, version 2
 * with the GNU Classpath Exception which is available at
 * https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 ********************************************************************************/
  
package org.eclipse.sprotty.xtext

import com.google.inject.Inject
import org.eclipse.lsp4j.Location
import org.eclipse.lsp4j.Range
import org.eclipse.sprotty.Action
import org.eclipse.sprotty.IDiagramSelectionListener
import org.eclipse.sprotty.IDiagramServer
import org.eclipse.sprotty.SModelIndex
import org.eclipse.sprotty.SelectAction
import org.eclipse.sprotty.xtext.ls.OpenInTextEditorMessage
import org.eclipse.sprotty.xtext.ls.SyncDiagramClient
import org.eclipse.sprotty.xtext.tracing.ITraceProvider
import org.eclipse.sprotty.xtext.tracing.TextRegionProvider
import org.eclipse.xtext.ide.server.UriExtensions

class DiagramSelectionListener implements IDiagramSelectionListener {
	
	@Inject extension UriExtensions
	
	@Inject extension ITraceProvider

	@Inject extension TextRegionProvider
	
	override selectionChanged(Action action, IDiagramServer server) {
		if (action instanceof SelectAction && server instanceof ILanguageAwareDiagramServer) {
			selectionChanged(action as SelectAction, server as ILanguageAwareDiagramServer)
		}
	}
	
	private def selectionChanged(SelectAction action, ILanguageAwareDiagramServer server) {
		if (action.preventOpenSelection) 
			return 
		val diagramLanguageClient = server.diagramLanguageServer.client
		if (diagramLanguageClient instanceof SyncDiagramClient) {
			if (action.selectedElementsIDs !== null && action.selectedElementsIDs.size === 1)  {
				val id = action.selectedElementsIDs.head
				val selectedElement = new SModelIndex(server.model).get(id)
				if (selectedElement?.trace !== null) {
					selectedElement.withSource(server) [ element, context |
						if (element !== null) {
							val traceRegion = element.significantRegion
							val start = context.document.getPosition(traceRegion.offset)
					 		val end = context.document.getPosition(traceRegion.offset + traceRegion.length)
					 		val uri = context.resource.URI.toUriString
							diagramLanguageClient.openInTextEditor(
								new OpenInTextEditorMessage(new Location(uri, new Range(start, end)), false)
							)
					 		return null
						}
					]
				}
			}
		}
	}
}
					