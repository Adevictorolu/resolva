import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/config/supabase_config.dart';
import '../data/models/order.dart';
import '../data/models/social_service.dart';
import '../data/models/exam_product.dart';
import 'auth_service.dart';

/// Service managing custom, responsive HTML email notifications formatted with
/// the Google Fonts **Montserrat** brand typography for:
/// - User Registration Activation & Verification Codes
/// - Password Reset & Security Verification Codes
/// - Examination E-PIN Deliveries (WAEC, NECO, NABTEB PINs + Serial Numbers)
/// - Social Media Boosting Order Fulfillment Receipts
/// - Paystack Wallet Funding Credit Receipts
class EmailNotificationService {
  EmailNotificationService._();

  static const String _montserratFontLink =
      '<link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700;800&display=swap" rel="stylesheet">';

  static const String _baseHeader = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>RESOLVA Notification</title>
  $_montserratFontLink
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #F8FAFC;
      font-family: 'Montserrat', Arial, -apple-system, sans-serif;
      color: #1E293B;
      -webkit-font-smoothing: antialiased;
    }
    .wrapper {
      width: 100%;
      background-color: #F8FAFC;
      padding: 30px 15px;
      box-sizing: border-box;
    }
    .container {
      max-width: 580px;
      margin: 0 auto;
      background-color: #FFFFFF;
      border-radius: 18px;
      overflow: hidden;
      box-shadow: 0 10px 25px -5px rgba(11, 27, 61, 0.08);
      border: 1px solid #E2E8F0;
    }
    .header {
      background: linear-gradient(135deg, #0B1B3D 0%, #1E3A8A 100%);
      padding: 36px 30px;
      text-align: center;
      color: #FFFFFF;
    }
    .header-logo {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: 2px;
      margin: 0;
      color: #FFFFFF;
    }
    .header-sub {
      font-size: 13px;
      color: #93C5FD;
      margin-top: 6px;
      letter-spacing: 0.5px;
    }
    .content {
      padding: 32px 30px;
    }
    .h1 {
      font-size: 20px;
      font-weight: 800;
      color: #0B1B3D;
      margin-top: 0;
      margin-bottom: 12px;
    }
    .p {
      font-size: 14px;
      line-height: 1.6;
      color: #475569;
      margin: 0 0 18px;
    }
    .btn {
      display: inline-block;
      background: #2563EB;
      color: #FFFFFF !important;
      text-decoration: none;
      padding: 14px 28px;
      border-radius: 999px;
      font-size: 14px;
      font-weight: 700;
      letter-spacing: 0.5px;
      box-shadow: 0 4px 12px rgba(37, 99, 235, 0.35);
      margin: 20px 0;
    }
    .pin-box {
      background-color: #EFF6FF;
      border: 1.5px dashed #2563EB;
      border-radius: 12px;
      padding: 16px;
      margin: 18px 0;
      text-align: center;
    }
    .pin-code {
      font-size: 22px;
      font-weight: 800;
      letter-spacing: 4px;
      color: #1E3A8A;
      font-family: monospace, 'Montserrat';
    }
    .detail-table {
      width: 100%;
      border-collapse: collapse;
      margin: 20px 0;
    }
    .detail-table td {
      padding: 11px 0;
      border-bottom: 1px solid #F1F5F9;
      font-size: 13.5px;
    }
    .detail-table td.label {
      color: #64748B;
      width: 40%;
    }
    .detail-table td.val {
      font-weight: 700;
      color: #0B1B3D;
      text-align: right;
    }
    .footer {
      background-color: #F8FAFC;
      border-top: 1px solid #E2E8F0;
      padding: 24px 30px;
      text-align: center;
      font-size: 12px;
      color: #94A3B8;
      line-height: 1.6;
    }
    .footer a {
      color: #2563EB;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="container">
      <div class="header">
        <h1 class="header-logo">RESOLVA</h1>
        <div class="header-sub">Social Media Boosting & Examination E-Pins Hub</div>
      </div>
      <div class="content">
''';

  static const String _baseFooter = '''
      </div>
      <div class="footer">
        <p style="margin: 0 0 6px;">Need assistance? Contact our team at <a href="mailto:${AppConfig.supportEmail}">${AppConfig.supportEmail}</a></p>
        <p style="margin: 0;">&copy; ${2026} RESOLVA Nigeria (<a href="${AppConfig.siteUrl}">${AppConfig.domain}</a>). All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>
''';

  // ─────────────────────────────────────────────────────────────────────────
  // 1. REGISTRATION ACTIVATION & EMAIL VERIFICATION TEMPLATE
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates the HTML for account activation / registration verification.
  static String buildActivationEmail({
    required String fullName,
    required String email,
    required String confirmationUrl,
    String? activationCode,
  }) {
    final codeHtml = activationCode != null && activationCode.isNotEmpty
        ? '''
        <div class="pin-box">
          <div style="font-size: 12px; font-weight: 600; color: #64748B; margin-bottom: 6px;">6-DIGIT ACTIVATION CODE</div>
          <div class="pin-code">$activationCode</div>
        </div>
        '''
        : '';

    return '''
$_baseHeader
        <h2 class="h1">Activate Your RESOLVA Account</h2>
        <p class="p">Hello <strong>$fullName</strong>,</p>
        <p class="p">Welcome to RESOLVA! To complete your registration and activate your secure customer dashboard, please confirm your email address by clicking the button below.</p>
        
        $codeHtml

        <div style="text-align: center;">
          <a href="$confirmationUrl" class="btn" target="_blank">Activate My Account</a>
        </div>

        <p class="p" style="font-size: 12.5px; color: #64748B;">If the button above does not work, copy and paste this verification link into your browser:<br>
          <a href="$confirmationUrl" style="color: #2563EB; word-break: break-all;">$confirmationUrl</a>
        </p>

        <p class="p" style="margin-top: 24px; font-size: 13px;">Once activated, you can set up your 6-digit transaction PIN, fund your wallet via Paystack, and access social media boosting and examination result checker e-pins instantly.</p>
$_baseFooter
''';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. PASSWORD RESET & VERIFICATION CODE TEMPLATE
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates the HTML for password reset.
  static String buildPasswordResetEmail({
    required String fullName,
    required String resetUrl,
    String? securityCode,
  }) {
    final codeHtml = securityCode != null && securityCode.isNotEmpty
        ? '''
        <div class="pin-box">
          <div style="font-size: 12px; font-weight: 600; color: #64748B; margin-bottom: 6px;">SECURITY RESET CODE</div>
          <div class="pin-code">$securityCode</div>
        </div>
        '''
        : '';

    return '''
$_baseHeader
        <h2 class="h1">Reset Your RESOLVA Password</h2>
        <p class="p">Hello <strong>$fullName</strong>,</p>
        <p class="p">We received a request to reset the password for your RESOLVA account. Click the button below to choose a new secure password.</p>

        $codeHtml

        <div style="text-align: center;">
          <a href="$resetUrl" class="btn" target="_blank">Reset Password</a>
        </div>

        <p class="p" style="font-size: 12.5px; color: #64748B;">This link is valid for 1 hour. If you did not request a password reset, you can safely ignore this email; your account remains secure.</p>
$_baseFooter
''';
  }

  /// Generates the HTML security alert when a password has been updated.
  static String buildPasswordChangedNotificationEmail({
    required String fullName,
    required String email,
    required String timestamp,
  }) {
    return '''
$_baseHeader
        <div style="text-align: center; margin-bottom: 20px;">
          <div style="display: inline-block; background-color: #DCFCE7; border: 1px solid #86EFAC; border-radius: 999px; padding: 10px 20px;">
            <span style="color: #15803D; font-weight: 700; font-size: 13px;">🛡️ Security Alert: Password Updated</span>
          </div>
        </div>

        <h2 class="h1">Password Successfully Changed</h2>
        <p class="p">Hello <strong>$fullName</strong>,</p>
        <p class="p">The sign-in password for your RESOLVA account (<strong>$email</strong>) was successfully changed on <strong>$timestamp</strong>.</p>

        <div style="background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 12px; padding: 18px; margin: 20px 0;">
          <p class="p" style="margin: 0; font-size: 13px; color: #334155;">
            <strong>Did you make this change?</strong><br>
            If you changed your password, no further action is required. Your account is secured.
          </p>
        </div>

        <p class="p" style="font-size: 12.5px; color: #DC2626;">
          <strong>Did not make this change?</strong><br>
          If you did not initiate this change, contact our support team immediately at <a href="mailto:${AppConfig.supportEmail}" style="color: #DC2626; font-weight: 700;">${AppConfig.supportEmail}</a> to secure your wallet and account.
        </p>
$_baseFooter
''';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. EXAMINATION E-PINS DELIVERY TEMPLATE
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates the official E-PIN delivery email with WAEC/NECO/NABTEB PINs.
  static String buildExamPinDeliveryEmail({
    required String fullName,
    required Order order,
    required ExamProduct product,
    required List<String> pins,
  }) {
    final pinsListHtml = pins.map((p) {
      return '''
      <div style="background-color: #F8FAFC; border: 1px solid #CBD5E1; border-radius: 10px; padding: 12px 16px; margin-bottom: 8px; font-family: monospace; font-size: 15px; font-weight: 800; color: #0B1B3D;">
        $p
      </div>
      ''';
    }).join('\n');

    final portalUrl = switch (product.provider.toUpperCase()) {
      'WAEC' => 'https://www.waecdirect.org',
      'NECO' => 'https://result.neco.gov.ng',
      'NABTEB' => 'https://eworld.nabteb.gov.ng',
      _ => '${AppConfig.siteUrl}/#/dashboard',
    };

    return '''
$_baseHeader
        <div style="display: inline-block; background-color: #DCFCE7; color: #15803D; font-size: 11px; font-weight: 800; padding: 4px 10px; border-radius: 999px; margin-bottom: 12px;">
          ✓ E-PIN ISSUED & VERIFIED
        </div>
        <h2 class="h1">${product.provider} Result Checker E-PIN Delivered</h2>
        <p class="p">Hello <strong>$fullName</strong>,</p>
        <p class="p">Thank you for your purchase. Your official <strong>${product.name}</strong> PIN(s) have been generated and are ready for use immediately.</p>

        <div style="margin: 22px 0;">
          <div style="font-size: 12px; font-weight: 700; color: #64748B; text-transform: uppercase; margin-bottom: 8px;">
            YOUR OFFICIAL RESULT CHECKER PIN(S) & SERIAL:
          </div>
          $pinsListHtml
        </div>

        <table class="detail-table">
          <tr>
            <td class="label">Transaction ID</td>
            <td class="val">${order.id}</td>
          </tr>
          <tr>
            <td class="label">Reference</td>
            <td class="val">${order.bigisubReference ?? order.id}</td>
          </tr>
          <tr>
            <td class="label">Examination</td>
            <td class="val">${product.provider}</td>
          </tr>
          <tr>
            <td class="label">Quantity</td>
            <td class="val">${order.quantity} PIN(s)</td>
          </tr>
          <tr>
            <td class="label">Total Paid</td>
            <td class="val">₦${order.amount.toStringAsFixed(2)}</td>
          </tr>
          <tr>
            <td class="label">Payment Source</td>
            <td class="val">RESOLVA Wallet</td>
          </tr>
        </table>

        <div style="background-color: #FEF3C7; border: 1px solid #FDE68A; border-radius: 12px; padding: 14px 16px; margin: 18px 0; font-size: 12.5px; color: #92400E; line-height: 1.5;">
          <strong>How to check your result:</strong><br>
          1. Visit the official ${product.provider} portal: <a href="$portalUrl" target="_blank" style="color: #B45309; font-weight: 700;">$portalUrl</a><br>
          2. Enter your Examination Number and Examination Year.<br>
          3. Enter the PIN and Serial Number provided above, then click <strong>Submit</strong>.
        </div>

        <p class="p" style="font-size: 12px; color: #64748B;">This receipt and all issued PINs are also permanently saved in your RESOLVA Account E-PIN Vault.</p>
$_baseFooter
''';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. SOCIAL MEDIA BOOSTING RECEIPT TEMPLATE
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates the HTML receipt for Social Media Boosting orders.
  static String buildSocialBoostingReceiptEmail({
    required String fullName,
    required Order order,
    required SocialService service,
    required String platformName,
  }) {
    return '''
$_baseHeader
        <div style="display: inline-block; background-color: #DBEAFE; color: #1E40AF; font-size: 11px; font-weight: 800; padding: 4px 10px; border-radius: 999px; margin-bottom: 12px;">
          ✓ DISPATCHED TO MARKETING HUB
        </div>
        <h2 class="h1">Social Media Boosting Order Confirmed</h2>
        <p class="p">Hello <strong>$fullName</strong>,</p>
        <p class="p">Your order for <strong>${service.name}</strong> has been received and queued with the upstream Marketing Hub network.</p>

        <table class="detail-table">
          <tr>
            <td class="label">Order ID</td>
            <td class="val">${order.id}</td>
          </tr>
          <tr>
            <td class="label">Platform</td>
            <td class="val">$platformName (${service.countryLabel})</td>
          </tr>
          <tr>
            <td class="label">Service</td>
            <td class="val">${service.name}</td>
          </tr>
          <tr>
            <td class="label">Target Link / Handle</td>
            <td class="val" style="word-break: break-all;">${order.targetUrl ?? 'N/A'}</td>
          </tr>
          <tr>
            <td class="label">Quantity</td>
            <td class="val">${order.quantity} units</td>
          </tr>
          <tr>
            <td class="label">Total Paid</td>
            <td class="val">₦${order.amount.toStringAsFixed(2)}</td>
          </tr>
          <tr>
            <td class="label">Estimated Delivery</td>
            <td class="val">${service.estimatedDelivery}</td>
          </tr>
          <tr>
            <td class="label">Status</td>
            <td class="val" style="color: #2563EB;">Processing / In Progress</td>
          </tr>
        </table>

        <div style="text-align: center; margin: 24px 0;">
          <a href="${AppConfig.siteUrl}/#/dashboard" class="btn" target="_blank">Track Order Live</a>
        </div>

        <p class="p" style="font-size: 12.5px; color: #64748B;">You can monitor the live delivery percentage, refill guarantee, and completion status anytime from your RESOLVA dashboard.</p>
$_baseFooter
''';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. WALLET FUNDING RECEIPT TEMPLATE
  // ─────────────────────────────────────────────────────────────────────────

  /// Generates the HTML receipt for Paystack wallet funding.
  static String buildWalletFundingReceiptEmail({
    required String fullName,
    required double amount,
    required String reference,
    required double newBalance,
    required String channel,
  }) {
    return '''
$_baseHeader
        <div style="display: inline-block; background-color: #DCFCE7; color: #15803D; font-size: 11px; font-weight: 800; padding: 4px 10px; border-radius: 999px; margin-bottom: 12px;">
          ✓ WALLET CREDITED
        </div>
        <h2 class="h1">Paystack Wallet Top-Up Successful</h2>
        <p class="p">Hello <strong>$fullName</strong>,</p>
        <p class="p">Your RESOLVA wallet has been credited with <strong>₦${amount.toStringAsFixed(2)}</strong> via Paystack payment confirmation.</p>

        <div class="pin-box" style="background-color: #F0FDF4; border-color: #16A34A;">
          <div style="font-size: 12px; font-weight: 600; color: #15803D; margin-bottom: 4px;">CREDITED AMOUNT</div>
          <div style="font-size: 26px; font-weight: 800; color: #166534;">+₦${amount.toStringAsFixed(2)}</div>
        </div>

        <table class="detail-table">
          <tr>
            <td class="label">Transaction Reference</td>
            <td class="val">$reference</td>
          </tr>
          <tr>
            <td class="label">Payment Method</td>
            <td class="val">Paystack ($channel)</td>
          </tr>
          <tr>
            <td class="label">Updated Wallet Balance</td>
            <td class="val" style="color: #16A34A;">₦${newBalance.toStringAsFixed(2)}</td>
          </tr>
          <tr>
            <td class="label">Date</td>
            <td class="val">${DateTime.now().toLocal().toString().split('.')[0]}</td>
          </tr>
        </table>

        <div style="text-align: center; margin: 20px 0;">
          <a href="${AppConfig.siteUrl}/#/dashboard" class="btn" target="_blank">Go to My Dashboard</a>
        </div>
$_baseFooter
''';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DISPATCH HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Sends an email notification to the recipient and records it in Supabase `public.email_notifications`.
  static Future<bool> sendEmail({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String htmlContent,
    required String templateType,
  }) async {
    final cleanEmail = recipientEmail.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) return false;

    // Log the email notification to Supabase table for audit & verification
    try {
      if (AuthService.isEnabled) {
        await AuthService.logEmailNotification(
          recipientEmail: cleanEmail,
          recipientName: recipientName,
          subject: subject,
          htmlContent: htmlContent,
          templateType: templateType,
        );
      }
    } catch (e) {
      debugPrint('[EmailNotificationService] Supabase log error: $e');
    }

    // Call Supabase Edge Function `send-email` if configured
    if (SupabaseConfig.isConfigured) {
      try {
        final url = Uri.parse('${SupabaseConfig.url}/functions/v1/send-email');
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.anonKey,
            'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          },
          body: jsonEncode({
            'to': cleanEmail,
            'to_name': recipientName,
            'subject': subject,
            'html': htmlContent,
            'template_type': templateType,
            'from': AppConfig.supportEmail,
          }),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {
        // Non-blocking
      }
    }

    debugPrint('[EmailNotificationService] Dispatched $templateType email to $cleanEmail ($subject)');
    return true;
  }
}
