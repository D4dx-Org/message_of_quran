import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/services/api/common_email_api.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/features/common_email/models/common_email_requests.dart';
import 'package:the_message_of_the_quran/features/common_email/presentation/widgets/common_email_form_widgets.dart';

const _feedbackAppName = 'Quran Asad Malayalam';
const _feedbackSource = 'the_message_of_the_quran';
const _feedbackPlatform = 'mobile';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, this.api});

  final CommonEmailApi? api;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  late final CommonEmailApi _fallbackApi = CommonEmailApi();

  FeedbackRating? _selectedRating;
  bool _isSubmitting = false;

  CommonEmailApi get _api => widget.api ?? _fallbackApi;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedRating == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _api.sendFeedback(
        FeedbackRequest(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          rating: _selectedRating!,
          message: _messageController.text.trim(),
          platform: _feedbackPlatform,
          source: _feedbackSource,
          appName: _feedbackAppName,
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _messageController.clear();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedRating = null;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Feedback sent successfully.')),
        );
    } on CommonEmailApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      appBar: CommonAppBar.homeAppBar(
        context,
        showOrnament: false,
        title: 'Feedback',
      ),
      drawer: const CommonDrawer(),
      resizeToAvoidBottomInset: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CommonEmailHeaderCard(
                title: 'Share your feedback',
                subtitle:
                    'Tell us what is working well and where the app can improve.',
                icon: Icons.chat_bubble_outline_rounded,
              ),
              const SizedBox(height: 20),
              CommonEmailSectionCard(
                child: Column(
                  children: [
                    CommonEmailTextField(
                      label: 'Name',
                      hintText: 'Enter your full name',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          CommonEmailValidators.required(value, 'your name'),
                    ),
                    const SizedBox(height: 16),
                    CommonEmailTextField(
                      label: 'Email',
                      hintText: 'Enter your email address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: CommonEmailValidators.email,
                    ),
                    const SizedBox(height: 16),
                    CommonEmailTextField(
                      label: 'Phone Number',
                      hintText: 'Enter your phone number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: CommonEmailValidators.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CommonEmailChoiceGroupField<FeedbackRating>(
                title: 'How would you rate the app?',
                subtitle: 'Select one option',
                value: _selectedRating,
                onChanged: (value) {
                  setState(() {
                    _selectedRating = value;
                  });
                },
                validator: (value) => CommonEmailValidators.selection(
                  value,
                  'Please choose a rating.',
                ),
                options: FeedbackRating.values
                    .map(
                      (rating) => CommonEmailChoice<FeedbackRating>(
                        value: rating,
                        label: rating.label,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              CommonEmailSectionCard(
                child: CommonEmailTextField(
                  label: 'Message',
                  hintText: 'Tell us about your experience',
                  controller: _messageController,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 5,
                  maxLines: 7,
                  validator: (value) => CommonEmailValidators.required(
                    value,
                    'your feedback message',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CommonEmailSubmitButton(
                key: const ValueKey('feedback-submit-button'),
                label: 'Send Feedback',
                isSubmitting: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              SelectableText(
                'We review all feedback and may reach out if we need more details.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
