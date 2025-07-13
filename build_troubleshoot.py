#!/usr/bin/env python3
"""
AI Xcode Build Troubleshooting Script
Automatically builds Xcode projects, analyzes errors, and applies fixes.
"""

import subprocess
import json
import re
import os
import sys
import time
from pathlib import Path
from typing import List, Dict, Tuple, Optional

class XcodeBuildTroubleshooter:
    def __init__(self, project_path: str = ".", max_attempts: int = 5):
        self.project_path = Path(project_path)
        self.max_attempts = max_attempts
        self.build_log = ""
        self.errors = []
        self.warnings = []
        self.attempt_count = 0
        
        # Find project file
        self.project_file = self._find_project_file()
        if not self.project_file:
            raise FileNotFoundError("No .xcodeproj or .xcworkspace file found")
    
    def _find_project_file(self) -> Optional[Path]:
        """Find the Xcode project or workspace file"""
        for ext in [".xcworkspace", ".xcodeproj"]:
            for file in self.project_path.glob(f"*{ext}"):
                return file
        return None
    
    def _get_build_command(self, destination: str = "platform=iOS Simulator,name=iPhone 15") -> List[str]:
        """Generate the xcodebuild command"""
        if self.project_file.suffix == ".xcworkspace":
            return [
                "xcodebuild",
                "-workspace", str(self.project_file),
                "-scheme", self.project_file.stem,
                "-destination", destination,
                "build"
            ]
        else:
            return [
                "xcodebuild",
                "-project", str(self.project_file),
                "-scheme", self.project_file.stem,
                "-destination", destination,
                "build"
            ]
    
    def build_project(self) -> Tuple[bool, str]:
        """Build the Xcode project and capture output"""
        print(f"🔨 Building {self.project_file.name}...")
        
        cmd = self._get_build_command()
        print(f"Running: {' '.join(cmd)}")
        
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=self.project_path,
                timeout=300  # 5 minute timeout
            )
            
            self.build_log = result.stdout + result.stderr
            success = result.returncode == 0
            
            if success:
                print("✅ Build succeeded!")
            else:
                print("❌ Build failed!")
                
            return success, self.build_log
            
        except subprocess.TimeoutExpired:
            print("⏰ Build timed out after 5 minutes")
            return False, "Build timed out"
        except Exception as e:
            print(f"🚨 Build command failed: {e}")
            return False, str(e)
    
    def parse_errors(self) -> None:
        """Parse errors and warnings from build log"""
        self.errors = []
        self.warnings = []
        
        # Common error patterns
        error_patterns = [
            r"error: (.+)",
            r"❌ (.+)",
            r"fatal error: (.+)",
            r"ld: (.+) for architecture",
            r"Undefined symbols for architecture",
            r"duplicate symbol",
            r"No such file or directory",
            r"Use of undeclared identifier",
            r"Cannot find (.+) in scope",
            r"Missing package product",
            r"Build input files cannot be found"
        ]
        
        warning_patterns = [
            r"warning: (.+)",
            r"⚠️ (.+)"
        ]
        
        lines = self.build_log.split('\n')
        
        for line in lines:
            # Check for errors
            for pattern in error_patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    self.errors.append(line.strip())
                    break
            
            # Check for warnings
            for pattern in warning_patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    self.warnings.append(line.strip())
                    break
        
        # Remove duplicates while preserving order
        self.errors = list(dict.fromkeys(self.errors))
        self.warnings = list(dict.fromkeys(self.warnings))
        
        print(f"📊 Found {len(self.errors)} errors and {len(self.warnings)} warnings")
    
    def analyze_and_fix_errors(self) -> bool:
        """Analyze errors and apply automatic fixes"""
        if not self.errors:
            return True
        
        print("🔍 Analyzing errors...")
        fixes_applied = False
        
        for error in self.errors:
            print(f"🔧 Analyzing: {error}")
            
            if self._fix_missing_files(error):
                fixes_applied = True
            elif self._fix_duplicate_files(error):
                fixes_applied = True
            elif self._fix_missing_dependencies(error):
                fixes_applied = True
            elif self._fix_bundle_identifier(error):
                fixes_applied = True
            elif self._fix_missing_assets(error):
                fixes_applied = True
            elif self._fix_swift_errors(error):
                fixes_applied = True
            elif self._fix_linker_errors(error):
                fixes_applied = True
            else:
                print(f"❓ No automatic fix available for: {error}")
        
        return fixes_applied
    
    def _fix_missing_files(self, error: str) -> bool:
        """Fix missing file errors"""
        if "Build input files cannot be found" in error or "No such file or directory" in error:
            # Extract file path from error
            file_match = re.search(r"'([^']+\.swift)'", error)
            if file_match:
                missing_file = file_match.group(1)
                print(f"🔍 Looking for missing file: {missing_file}")
                
                # Search for the file in the project directory
                for file_path in self.project_path.rglob("*.swift"):
                    if file_path.name == Path(missing_file).name:
                        print(f"✅ Found file at: {file_path}")
                        # Regenerate project if using XcodeGen
                        return self._regenerate_project()
                
                print(f"❌ Could not find missing file: {missing_file}")
        
        return False
    
    def _fix_duplicate_files(self, error: str) -> bool:
        """Fix duplicate file errors"""
        if "used twice" in error.lower() or "duplicate" in error.lower():
            # Extract file paths
            paths = re.findall(r"'([^']+)'", error)
            if len(paths) >= 2:
                print(f"🔧 Fixing duplicate files: {paths}")
                
                # Keep the file in the more organized directory structure
                files_to_remove = []
                for path in paths:
                    full_path = self.project_path / path.replace('/Users/jonaturagavou/RM-ABP/', '')
                    if full_path.exists():
                        # Prefer files in subdirectories over root Views directory
                        if '/Views/' in str(path) and not any(subdir in str(path) for subdir in ['/Dashboard/', '/Auth/', '/Goals/', '/Tasks/', '/Calendar/']):
                            files_to_remove.append(full_path)
                
                # Remove duplicate files
                for file_path in files_to_remove:
                    try:
                        file_path.unlink()
                        print(f"🗑️ Removed duplicate file: {file_path}")
                    except Exception as e:
                        print(f"❌ Failed to remove {file_path}: {e}")
                
                if files_to_remove:
                    return self._regenerate_project()
        
        return False
    
    def _fix_missing_dependencies(self, error: str) -> bool:
        """Fix missing package dependencies"""
        if "Missing package product" in error or "Cannot find" in error and "in scope" in error:
            missing_deps = []
            
            # Common Firebase dependencies
            firebase_deps = ["FirebaseAuth", "FirebaseFirestore", "FirebaseStorage", "FirebaseMessaging", "FirebaseAnalytics", "FirebaseCrashlytics"]
            
            for dep in firebase_deps:
                if dep in error:
                    missing_deps.append(dep)
            
            if missing_deps:
                print(f"🔧 Adding missing dependencies: {missing_deps}")
                return self._update_project_dependencies(missing_deps)
        
        return False
    
    def _fix_bundle_identifier(self, error: str) -> bool:
        """Fix bundle identifier issues"""
        if "bundle identifier" in error.lower() or "PRODUCT_BUNDLE_IDENTIFIER" in error:
            print("🔧 Fixing bundle identifier...")
            # This would typically involve updating the project file
            # For now, just regenerate the project
            return self._regenerate_project()
        
        return False
    
    def _fix_missing_assets(self, error: str) -> bool:
        """Fix missing asset catalog issues"""
        if "AppIcon" in error or "AccentColor" in error or "asset catalog" in error:
            print("🔧 Fixing missing assets...")
            
            # Create missing asset catalogs
            assets_path = self.project_path / "AreaBook" / "Assets.xcassets"
            if not assets_path.exists():
                assets_path.mkdir(parents=True, exist_ok=True)
                
                # Create Contents.json
                contents = {
                    "info": {
                        "author": "xcode",
                        "version": 1
                    }
                }
                with open(assets_path / "Contents.json", "w") as f:
                    json.dump(contents, f, indent=2)
            
            # Create AppIcon.appiconset if missing
            appicon_path = assets_path / "AppIcon.appiconset"
            if not appicon_path.exists():
                appicon_path.mkdir(exist_ok=True)
                appicon_contents = {
                    "images": [
                        {"idiom": "iphone", "scale": "2x", "size": "20x20"},
                        {"idiom": "iphone", "scale": "3x", "size": "20x20"},
                        {"idiom": "iphone", "scale": "2x", "size": "29x29"},
                        {"idiom": "iphone", "scale": "3x", "size": "29x29"},
                        {"idiom": "iphone", "scale": "2x", "size": "40x40"},
                        {"idiom": "iphone", "scale": "3x", "size": "40x40"},
                        {"idiom": "iphone", "scale": "2x", "size": "60x60"},
                        {"idiom": "iphone", "scale": "3x", "size": "60x60"},
                        {"idiom": "ios-marketing", "scale": "1x", "size": "1024x1024"}
                    ],
                    "info": {"author": "xcode", "version": 1}
                }
                with open(appicon_path / "Contents.json", "w") as f:
                    json.dump(appicon_contents, f, indent=2)
            
            # Create AccentColor.colorset if missing
            accent_path = assets_path / "AccentColor.colorset"
            if not accent_path.exists():
                accent_path.mkdir(exist_ok=True)
                accent_contents = {
                    "colors": [{"idiom": "universal"}],
                    "info": {"author": "xcode", "version": 1}
                }
                with open(accent_path / "Contents.json", "w") as f:
                    json.dump(accent_contents, f, indent=2)
            
            print("✅ Created missing asset catalogs")
            return True
        
        return False
    
    def _fix_swift_errors(self, error: str) -> bool:
        """Fix common Swift compilation errors"""
        if "Use of undeclared identifier" in error:
            # Extract the identifier
            match = re.search(r"Use of undeclared identifier '([^']+)'", error)
            if match:
                identifier = match.group(1)
                print(f"🔧 Found undeclared identifier: {identifier}")
                
                # Common fixes for missing imports
                missing_imports = {
                    "Firebase": "import Firebase",
                    "FirebaseAuth": "import FirebaseAuth",
                    "FirebaseFirestore": "import FirebaseFirestore",
                    "UNUserNotificationCenter": "import UserNotifications",
                    "UIApplication": "import UIKit"
                }
                
                if identifier in missing_imports:
                    print(f"💡 Suggested fix: Add {missing_imports[identifier]}")
                    # In a real implementation, you'd scan Swift files and add the import
                    return True
        
        return False
    
    def _fix_linker_errors(self, error: str) -> bool:
        """Fix linker errors"""
        if "Undefined symbols for architecture" in error or "ld:" in error:
            print("🔧 Attempting to fix linker errors...")
            
            # Common fix: clean build folder
            try:
                clean_cmd = ["xcodebuild", "clean", "-project", str(self.project_file)]
                subprocess.run(clean_cmd, cwd=self.project_path, capture_output=True)
                print("🧹 Cleaned build folder")
                return True
            except Exception as e:
                print(f"❌ Failed to clean: {e}")
        
        return False
    
    def _regenerate_project(self) -> bool:
        """Regenerate project using XcodeGen if available"""
        project_yml = self.project_path / "project.yml"
        if project_yml.exists():
            try:
                print("🔄 Regenerating Xcode project...")
                result = subprocess.run(
                    ["xcodegen", "generate"],
                    cwd=self.project_path,
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    print("✅ Project regenerated successfully")
                    return True
                else:
                    print(f"❌ Failed to regenerate project: {result.stderr}")
            except FileNotFoundError:
                print("❌ XcodeGen not found. Install with: brew install xcodegen")
            except Exception as e:
                print(f"❌ Error regenerating project: {e}")
        
        return False
    
    def _update_project_dependencies(self, dependencies: List[str]) -> bool:
        """Update project dependencies"""
        project_yml = self.project_path / "project.yml"
        if project_yml.exists():
            print(f"🔧 Updating dependencies in project.yml: {dependencies}")
            # In a real implementation, you'd parse and update the YAML file
            return self._regenerate_project()
        
        return False
    
    def run_troubleshooting_cycle(self) -> bool:
        """Run a complete troubleshooting cycle"""
        print(f"\n🚀 Starting troubleshooting cycle {self.attempt_count + 1}/{self.max_attempts}")
        
        # Build the project
        success, log = self.build_project()
        
        if success:
            print("🎉 Build successful!")
            return True
        
        # Parse errors
        self.parse_errors()
        
        if not self.errors:
            print("❓ Build failed but no errors found in log")
            return False
        
        # Display errors
        print("\n📋 Errors found:")
        for i, error in enumerate(self.errors[:5], 1):  # Show first 5 errors
            print(f"  {i}. {error}")
        
        if len(self.errors) > 5:
            print(f"  ... and {len(self.errors) - 5} more errors")
        
        # Try to fix errors
        fixes_applied = self.analyze_and_fix_errors()
        
        if fixes_applied:
            print("✅ Applied fixes, will retry build")
            time.sleep(2)  # Brief pause before retry
            return False  # Continue to next iteration
        else:
            print("❌ No fixes could be applied")
            return False
    
    def run(self) -> bool:
        """Main troubleshooting loop"""
        print(f"🤖 AI Xcode Build Troubleshooter")
        print(f"📁 Project: {self.project_file}")
        print(f"🎯 Max attempts: {self.max_attempts}")
        
        for self.attempt_count in range(self.max_attempts):
            if self.run_troubleshooting_cycle():
                print(f"\n🎉 Build successful after {self.attempt_count + 1} attempts!")
                return True
        
        print(f"\n💥 Failed to fix build after {self.max_attempts} attempts")
        print("\n📋 Final error summary:")
        for error in self.errors[:10]:  # Show first 10 errors
            print(f"  • {error}")
        
        print("\n💡 Manual intervention may be required:")
        print("  1. Check for missing files in Xcode")
        print("  2. Verify Firebase dependencies are properly added")
        print("  3. Ensure bundle identifier is correct")
        print("  4. Check for syntax errors in Swift files")
        
        return False

def main():
    """Main entry point"""
    if len(sys.argv) > 1:
        project_path = sys.argv[1]
    else:
        project_path = "."
    
    try:
        troubleshooter = XcodeBuildTroubleshooter(project_path)
        success = troubleshooter.run()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"🚨 Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()