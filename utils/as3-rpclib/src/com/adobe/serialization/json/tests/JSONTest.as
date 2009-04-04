/*
Adobe Systems Incorporated(r) Source Code License Agreement
Copyright(c) 2005 Adobe Systems Incorporated. All rights reserved.
	
Please read this Source Code License Agreement carefully before using
the source code.
	
Adobe Systems Incorporated grants to you a perpetual, worldwide, non-exclusive,
no-charge, royalty-free, irrevocable copyright license, to reproduce,
prepare derivative works of, publicly display, publicly perform, and
distribute this source code and such derivative works in source or
object code form without any attribution requirements.
	
The name "Adobe Systems Incorporated" must not be used to endorse or promote products
derived from the source code without prior written permission.
	
You agree to indemnify, hold harmless and defend Adobe Systems Incorporated from and
against any loss, damage, claims or lawsuits, including attorney's
fees that arise or result from your use or distribution of the source
code.
	
THIS SOURCE CODE IS PROVIDED "AS IS" AND "WITH ALL FAULTS", WITHOUT
ANY TECHNICAL SUPPORT OR ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING,
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE ARE DISCLAIMED. ALSO, THERE IS NO WARRANTY OF
NON-INFRINGEMENT, TITLE OR QUIET ENJOYMENT. IN NO EVENT SHALL MACROMEDIA
OR ITS SUPPLIERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOURCE CODE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package com.adobe.serialization.json.tests {

	import flexunit.framework.TestCase;
	import flexunit.framework.TestSuite;
	
	import com.adobe.serialization.json.JSONDecoder;
	import com.adobe.serialization.json.JSONEncoder;
	import com.adobe.serialization.json.JSON;
	
	public class JSONTest extends TestCase {
		
	    public function JSONTest( methodName:String = null) {
			super( methodName );
        }
		
		/**
		 * Test for the JSON string true decoded to boolean true.
		 */
		public function testDecodeTrue():void {
			var o:Object = JSON.decode( "  	 true    " );
			assertTrue( "Expected decoded true", o == true );
		}
		
		public function testDecodeFalse():void {
			var o:Object = JSON.decode( "  	 false " );
			assertTrue( "Expected decoded false", o == false );
		}
		
		public function testDecodeNull():void {
			var o:Object = JSON.decode( "null " );
			assertTrue( "Expected decoded null", o == null );
		}
		
		public function testDecodeString():void {
			var o:Object = JSON.decode( ' "this is \t a string \n with \' escapes" ' );
			assertTrue( "String not decoded successfully", o == "this is \t a string \n with \' escapes" );
			
			o = JSON.decode( ' "http:\/\/digg.com\/security\/Simple_Digg_Hack" ' );
			assertTrue( "String not decoded correctly", o == "http://digg.com/security/Simple_Digg_Hack" );
		}
		
		public function testDecodeObject():void {
			var o:Object = JSON.decode( " { \"test\": true, \"test2\": -12356732.12 } " );
			assertTrue( "Expected decoded object.test = true", o.test == true );
			assertTrue( "Expected decoded object.test2 = -12356732.12", o.test2 == -12356732.12 );
		}
		
		public function testDecodeArray():void {
			var o:Object = JSON.decode( " [ null, true, false, 100, -100, \"test\", { \"foo\": \"bar\" } ] "  );
			assertTrue( "Expected decoded array[0] == null", o[0] == null );
			assertTrue( "Expected decoded array[1] == true", o[1] == true );
			assertTrue( "Expected decoded array[2] == false", o[2] == false );
			assertTrue( "Expected decoded array[3] == 100", o[3] == 100 );
			assertTrue( "Expected decoded array[4] == -100", o[4] == -100 );
			assertTrue( "Expected decoded array[5] == \"test\"", o[5] == "test" );
			assertTrue( "Expected decoded array[6].foo == \"bar\"", o[6].foo == "bar" );
		}
		
		public function testEncodeTrue():void {
			var o:String = JSON.encode( true );
			assertTrue( "Expected encoded true", o == "true" );
		}
		
		public function testEncodeFalse():void {
			var o:String = JSON.encode( false );
			assertTrue( "Expected encoded false", o == "false" );
		}
		
		public function testEncodeNull():void {
			var o:String = JSON.encode( null );
			assertTrue( "Expected encoded null", o == "null" );
		}
		
		public function testEncodeString():void {
			var o:String = JSON.encode( "this is a \n \"string\"" );
			assertTrue( "Expected encoded string", o == "\"this is a \\n \\\"string\\\"\"" );
		}
		
		public function testEncodeArrayEmpty():void {
			var o:String = JSON.encode( [] );
			assertTrue( "Expected encoded []", o == "[]" );
		}
		
		public function testEncodeArray():void {
			var o:String = JSON.encode( [ true, false, -10, null, Number.NEGATIVE_INFINITY ] );
			assertTrue( "Expected encoded array", o == "[true,false,-10,null,null]" );
		}
		
		public function testEncodeObjectEmpty():void {
			var o:String = JSON.encode( {} );
			assertTrue( "Expected encoded {}", o == "{}" );
		}
		
		public function testEncodeObject():void {
			// Note: because order cannot be guaranteed when decoding
			// into a string, we can't reliably test an object with
			// multiple properties, so instead we test multiple
			// smaller objects
			//var obj:Object = new Object();
			//obj.test1 = true;
			//obj["test 2"] = false;
			//obj[" test _3" ] = { foo: "bar" };
			
			//var o:String = JSON.encode( obj );
			//assertTrue( "Expected encoded object", o == "{\"test1\":true,\"test 2\":false,\" test _3\":{\"foo\":\"bar\"}}" );
			
			var obj:Object = { foo: { foo2: { foo3: { foo4: "bar" } } } };
			var s:String = JSON.encode( obj );
			assertTrue( "Deeply nested", "{\"foo\":{\"foo2\":{\"foo3\":{\"foo4\":\"bar\"}}}}" );
			
			obj = new Object();
			obj[" prop with spaces "] = true;
			assertTrue( "Prop with spaces", "{\" prop with spaces \":true}" );
		}
	}
		
}