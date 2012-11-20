package org.eclipse.xtend.core.tests.formatting

import java.util.Collection
import javax.inject.Inject
import org.eclipse.xtend.core.formatting.XtendFormatter
import org.eclipse.xtend.core.formatting.XtendFormatterConfigKeys
import org.eclipse.xtend.core.tests.compiler.batch.XtendInjectorProvider
import org.eclipse.xtend.core.xtend.XtendFile
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.xbase.configuration.MapBasedConfigurationValues
import org.eclipse.xtext.xbase.formatting.TextReplacement
import org.junit.Assert
import org.junit.runner.RunWith

@RunWith(typeof(XtextRunner))
@InjectWith(typeof(XtendInjectorProvider))
abstract class AbstractFormatterTest {
	@Inject extension ParseHelper<XtendFile>
	@Inject XtendFormatter formatter
	@Inject XtendFormatterConfigKeys keys
	
	def assertFormatted(CharSequence toBeFormatted) {
		assertFormatted(toBeFormatted, toBeFormatted /* .parse.flattenWhitespace  */)
	}
	
	def private toMember(CharSequence expression) '''
		package foo
		
		class bar {
			�expression�
		}
	'''
	
	def assertFormattedExpression((MapBasedConfigurationValues) => void cfg, CharSequence toBeFormatted) {
		assertFormattedExpression(cfg, toBeFormatted, toBeFormatted)
	}
	
	def assertFormattedExpression(CharSequence toBeFormatted) {
		assertFormattedExpression(null, toBeFormatted, toBeFormatted)
	}
	
	def assertFormattedExpression(String expectation, CharSequence toBeFormatted) {
		assertFormattedExpression(null, expectation, toBeFormatted)
	}
	
	def assertFormattedExpression((MapBasedConfigurationValues) => void cfg, CharSequence expectation, CharSequence toBeFormatted) {
		assertFormattedExpression(cfg, expectation, toBeFormatted, false)		
	}
	
	def assertFormattedExpression((MapBasedConfigurationValues) => void cfg, CharSequence expectation, CharSequence toBeFormatted, boolean allowErrors) {
		assertFormatted(cfg, expectation.toString.trim.replace("\n", "\n\t\t"), toBeFormatted.toString.trim.replace("\n", "\n\t\t"), "class bar {\n\tdef baz() {\n\t\t", "\n\t}\n}", allowErrors)
	}
	
	def assertFormattedMember(String expectation, CharSequence toBeFormatted) {
		assertFormatted(expectation.toMember, toBeFormatted.toMember)
	}
	
	def assertFormattedMember((MapBasedConfigurationValues) => void cfg, String expectation, CharSequence toBeFormatted) {
		assertFormatted(cfg, expectation.toMember, toBeFormatted.toMember)
	}
	
	def assertFormattedMember((MapBasedConfigurationValues) => void cfg, String expectation) {
		assertFormatted(cfg, expectation.toMember, expectation.toMember)
	}
	
	def assertFormattedMember(String expectation) {
		assertFormatted(expectation.toMember, expectation.toMember)
	}
	
	def createMissingEditReplacements(XtextResource res, Collection<TextReplacement> edits, int offset, int length) {
		val offsets = edits.map[it.offset].toSet
		val result = <TextReplacement>newArrayList
		var lastOffset = 0
		for(leaf:res.parseResult.rootNode.leafNodes) 
			if(!leaf.hidden || !leaf.text.trim.empty) {
				if((lastOffset >= offset) && (leaf.offset <= offset + length) && !offsets.contains(lastOffset))
					result += new TextReplacement(lastOffset, leaf.offset - lastOffset, "!!")
				lastOffset = leaf.offset + leaf.length
			}
		result
	}
	
	def assertFormatted((MapBasedConfigurationValues) => void cfg, CharSequence expectation) {
		assertFormatted(cfg, expectation, expectation)
	}
	
	def assertFormatted(CharSequence expectation, CharSequence toBeFormatted) {
		assertFormatted(null, expectation, toBeFormatted)
	}
	
	def assertFormatted((MapBasedConfigurationValues) => void cfg, CharSequence expectation, CharSequence toBeFormatted) {
		assertFormatted(cfg, expectation, toBeFormatted, "", "", false)	
	}
	
	def assertFormatted((MapBasedConfigurationValues) => void cfg, CharSequence expectation, CharSequence toBeFormatted, String prefix, String postfix, boolean allowErrors) {
		val fullToBeParsed = (prefix + toBeFormatted + postfix)
		val parsed = fullToBeParsed.parse
		if(!allowErrors)
			Assert::assertEquals(parsed.eResource.errors.join("\n"), 0, parsed.eResource.errors.size)
		val oldDocument = (parsed.eResource as XtextResource).parseResult.rootNode.text
		val rc = new MapBasedConfigurationValues(keys)

		rc.put(keys.maxLineWidth, 80)
		if(cfg != null)
			cfg.apply(rc)

		formatter.allowIdentityEdits = true
		
		// Step 1: Ensure formatted document equals expectation
		val start = prefix.length
		val length = toBeFormatted.length
		val edits = <TextReplacement>newLinkedHashSet
		edits += formatter.format(parsed.eResource as XtextResource, start, length, rc)
		if(!allowErrors)
			edits += createMissingEditReplacements(parsed.eResource as XtextResource, edits, start, length)
		val newDocument = oldDocument.applyEdits(edits)
		try {
			Assert::assertEquals((prefix + expectation + postfix).toString, newDocument.toString)
		} catch(AssertionError e) {
			println(oldDocument.applyDebugEdits(edits))
			println()
			throw e
		}
		
		// Step 2: Ensure formatting the document again doesn't change the document
		val parsed2Doc = fullToBeParsed.applyEdits(formatter.format(parsed.eResource as XtextResource, 0, fullToBeParsed.length, rc))
		val parsed2 = parsed2Doc.parse
		if(!allowErrors)
			Assert::assertEquals(0, parsed2.eResource.errors.size)
		val edits2 = formatter.format(parsed2.eResource as XtextResource, 0, parsed2Doc.length, rc)
		val newDocument2 = parsed2Doc.applyEdits(edits2)
		try {
			Assert::assertEquals(parsed2Doc, newDocument2.toString)
		} catch(AssertionError e) {
			println(newDocument.applyDebugEdits(edits2))
			println()
			throw e
		}
	}
	
	def protected String applyEdits(String oldDocument, Collection<TextReplacement> edits) {
		var lastOffset = 0
		val newDocument = new StringBuilder()
		for(edit:edits.sortBy[offset]) {
			newDocument.append(oldDocument.substring(lastOffset, edit.offset))
			newDocument.append(edit.text)
			lastOffset = edit.offset + edit.length
		}
		newDocument.append(oldDocument.substring(lastOffset, oldDocument.length))
		newDocument.toString
	}
	
	def protected String applyDebugEdits(String oldDocument, Collection<TextReplacement> edits) {
		var lastOffset = 0
		val debugTrace = new StringBuilder()
		for(edit:edits.sortBy[offset]) {
			debugTrace.append(oldDocument.substring(lastOffset, edit.offset))
			debugTrace.append('''[�oldDocument.substring(edit.offset, edit.offset + edit.length)�|�edit.text�]''')
			lastOffset = edit.offset + edit.length
		}
		debugTrace.append(oldDocument.substring(lastOffset, oldDocument.length))
		debugTrace.toString
	}
}
