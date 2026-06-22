import React, { useState } from 'react';

export default function Legal({ onCancel, initialTab = 'privacy' }) {
  const [activeTab, setActiveTab] = useState(initialTab);

  return (
    <main className="relative z-10 pt-20 px-4 max-w-2xl mx-auto pb-24">
      <div className="glass-card rounded-2xl p-6 shadow-xl space-y-6">
        
        {/* Header */}
        <div className="flex items-center gap-4 border-b border-diaroAccent-500/20 pb-4">
          <button 
            onClick={onCancel}
            className="flex items-center gap-1.5 text-diaroAccent-300/60 hover:text-white transition-colors"
          >
            <span className="material-symbols-outlined text-[20px]">arrow_back</span>
          </button>
          <h2 className="text-xl font-semibold text-white">Legal & Privacy</h2>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 border-b border-diaroAccent-500/10 pb-2 overflow-x-auto no-scrollbar">
          <button 
            onClick={() => setActiveTab('privacy')}
            className={`px-4 py-2 text-xs font-mono uppercase tracking-wider rounded-lg transition-colors whitespace-nowrap
              ${activeTab === 'privacy' ? 'bg-diaroAccent-600/30 text-diaroAccent-400' : 'text-diaroAccent-300/50 hover:text-white'}
            `}
          >
            Privacy Policy
          </button>
          <button 
            onClick={() => setActiveTab('tos')}
            className={`px-4 py-2 text-xs font-mono uppercase tracking-wider rounded-lg transition-colors whitespace-nowrap
              ${activeTab === 'tos' ? 'bg-diaroAccent-600/30 text-diaroAccent-400' : 'text-diaroAccent-300/50 hover:text-white'}
            `}
          >
            Terms of Service
          </button>
          <button 
            onClick={() => setActiveTab('deletion')}
            className={`px-4 py-2 text-xs font-mono uppercase tracking-wider rounded-lg transition-colors whitespace-nowrap
              ${activeTab === 'deletion' ? 'bg-red-900/30 text-red-400' : 'text-red-300/50 hover:text-white'}
            `}
          >
            Account Deletion
          </button>
        </div>

        {/* Content Area */}
        <div className="text-sm text-diaroAccent-100/80 leading-relaxed font-sans space-y-4 max-h-[60vh] overflow-y-auto pr-2 custom-scrollbar">
          
          {activeTab === 'privacy' && (
            <div className="space-y-4 animate-fade-in">
              <h3 className="text-lg font-semibold text-white">Privacy Policy</h3>
              <p>Last updated: 22 June 2026</p>
              <p>Diaro is designed with privacy as a core principle. We employ a zero-knowledge architecture where journal content is encrypted locally before synchronization.</p>
              
              <h4 className="font-semibold text-diaroAccent-300 mt-4">1. Information We Collect</h4>
              <p>We may collect:</p>
              <ul className="list-disc pl-5 space-y-1">
                <li><strong>Account Information:</strong> Email address, Username, Authentication identifiers</li>
                <li><strong>Encrypted User Data:</strong> Journal entries, Notes, Media attachments, Tags, Mood metadata</li>
              </ul>
              <p>All journal content is encrypted before transmission and storage.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">2. How We Use Information</h4>
              <p>We use collected information to:</p>
              <ul className="list-disc pl-5 space-y-1">
                <li>Authenticate users</li>
                <li>Synchronize encrypted data across devices</li>
                <li>Maintain account functionality</li>
                <li>Improve application reliability and security</li>
              </ul>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">3. Zero-Knowledge Encryption</h4>
              <p>Your master password is never transmitted to our servers in plaintext. Encryption keys are derived locally on your device using industry-standard cryptographic techniques. Because of this architecture, Diaro cannot decrypt or access your journal content. If you lose both your master password and recovery key, your encrypted data cannot be recovered.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">4. Data Sharing</h4>
              <p>We do not sell, rent, or trade personal information. We may share limited information only when:</p>
              <ul className="list-disc pl-5 space-y-1">
                <li>Required by law.</li>
                <li>Necessary to protect the security of the Service.</li>
                <li>Required to operate essential infrastructure providers.</li>
              </ul>
              <p>Encrypted journal content remains inaccessible to us.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">5. Data Retention</h4>
              <p>Data is retained while your account remains active. Upon account deletion, all associated user data is permanently removed from our systems subject to technical processing delays.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">6. Security</h4>
              <p>We implement industry-standard security measures including: HTTPS/TLS encryption, Secure authentication, Encrypted cloud storage, and Access controls. No security system can guarantee absolute protection.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">7. Your Rights</h4>
              <p>You may: Access your account information, Delete individual notes, Delete your entire account, or Request information regarding stored account data.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">8. Children's Privacy</h4>
              <p>Diaro is not intended for children under 13 years of age.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">9. Changes to This Policy</h4>
              <p>We may update this Privacy Policy periodically. Updated versions will be posted within the application.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">10. Contact</h4>
              <p>For privacy-related questions: <a href="mailto:support@diaro.app" className="text-diaroAccent-400 hover:underline">support@diaro.app</a></p>
            </div>
          )}

          {activeTab === 'tos' && (
            <div className="space-y-4 animate-fade-in">
              <h3 className="text-lg font-semibold text-white">Terms of Service</h3>
              <p>Last Updated: 22 June 2026</p>
              
              <h4 className="font-semibold text-diaroAccent-300 mt-4">1. Acceptance of Terms</h4>
              <p>By accessing or using Diaro ("the Service"), you agree to be bound by these Terms of Service. If you do not agree to these terms, you may not use the Service.</p>
              
              <h4 className="font-semibold text-diaroAccent-300 mt-4">2. Eligibility</h4>
              <p>You must be at least 13 years old (or the minimum age required in your jurisdiction) to use Diaro.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">3. User Responsibilities</h4>
              <p>You are responsible for:</p>
              <ul className="list-disc pl-5 space-y-1">
                <li>Maintaining the confidentiality of your account credentials.</li>
                <li>Safeguarding your master password and recovery key.</li>
                <li>All activity that occurs under your account.</li>
              </ul>
              <p>Because Diaro uses end-to-end encryption and a zero-knowledge architecture, lost passwords or recovery keys may result in permanent loss of access to your encrypted data.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">4. Acceptable Use</h4>
              <p>You agree not to:</p>
              <ul className="list-disc pl-5 space-y-1">
                <li>Use the Service for unlawful purposes.</li>
                <li>Attempt unauthorized access to systems or accounts.</li>
                <li>Distribute malware, harmful code, or abusive content.</li>
                <li>Interfere with the operation or security of the Service.</li>
              </ul>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">5. Intellectual Property</h4>
              <p>The Diaro application, branding, logos, design elements, and software are protected by applicable intellectual property laws and remain the property of their respective owners. Users retain ownership of all journal entries, notes, media, and content they create within Diaro.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">6. Service Availability</h4>
              <p>We strive to provide reliable access to the Service but do not guarantee uninterrupted availability. Maintenance, updates, technical issues, or circumstances beyond our control may result in temporary service disruptions.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">7. Limitation of Liability</h4>
              <p>The Service is provided "as is" and "as available" without warranties of any kind. To the maximum extent permitted by law, Diaro shall not be liable for: Data loss caused by forgotten credentials, Service interruptions, Unauthorized access resulting from compromised user devices, or Indirect, incidental, or consequential damages.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">8. Termination</h4>
              <p>We reserve the right to suspend or terminate accounts that violate these Terms. Users may delete their account at any time through the application settings.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">9. Changes to Terms</h4>
              <p>We may update these Terms periodically. Continued use of the Service after changes become effective constitutes acceptance of the revised Terms.</p>

              <h4 className="font-semibold text-diaroAccent-300 mt-4">10. Contact</h4>
              <p>For questions regarding these Terms, contact: <a href="mailto:support@diaro.app" className="text-diaroAccent-400 hover:underline">support@diaro.app</a></p>
            </div>
          )}

          {activeTab === 'deletion' && (
            <div className="space-y-4 animate-fade-in">
              <h3 className="text-lg font-semibold text-red-400">Account Deletion Policy</h3>
              <p>You have the right to completely erase your footprint from Diaro.</p>
              <ul className="list-disc pl-5 space-y-2">
                <li>Deleting a specific note permanently removes it from the cloud database and your local device.</li>
                <li>If you wish to delete your entire account, you can do so from the Settings menu.</li>
                <li><strong>Warning:</strong> Account deletion is irreversible. It instantly drops your user profile, all encrypted notes, media, and audit logs. No backups are retained.</li>
              </ul>
              <div className="p-4 bg-red-950/20 border border-red-500/30 rounded-xl mt-4">
                <p className="text-xs font-mono text-red-300/80">
                  To proceed with full account deletion, navigate to the <strong className="text-red-400">Settings</strong> page and select "Delete Account".
                </p>
              </div>
            </div>
          )}

        </div>

      </div>
    </main>
  );
}
