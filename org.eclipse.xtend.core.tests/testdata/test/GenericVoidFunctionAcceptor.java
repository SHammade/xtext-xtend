/*******************************************************************************
 * Copyright (c) 2013 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package test;

/**
 * @author Sven Efftinge - Initial contribution and API
 */
public class GenericVoidFunctionAcceptor {

	public static <T> T accept(T t, GenericVoidFunction<T> func) {
		func.doStuff(t);
		return t;
	}

}