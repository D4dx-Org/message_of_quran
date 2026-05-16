import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/services/api/common_email_api.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/common_email/models/common_email_requests.dart';
import 'package:the_message_of_the_quran/features/common_email/presentation/widgets/common_email_form_widgets.dart';

const _featureRequestAppName = 'The Message of The Quran';
const _featureRequestSource = 'the_message_of_the_quran';
const _featureRequestPlatform = 'mobile';

class FeatureRequestScreen extends StatefulWidget {
  const FeatureRequestScreen({super.key, this.api});

  final CommonEmailApi? api;

  @override
  State<FeatureRequestScreen> createState() => _FeatureRequestScreenState();
}

class _FeatureRequestScreenState extends State<FeatureRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final CommonEmailApi _fallbackApi = CommonEmailApi();

  FeatureRequestTargetPlatform? _selectedTargetPlatform;
  FeatureRequestCategory? _selectedCategory;
  bool _isSubmitting = false;

  CommonEmailApi get _api => widget.api ?? _fallbackApi;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid ||
        _selectedTargetPlatform == null ||
        _selectedCategory == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _api.sendFeatureRequest(
        FeatureRequestSubmission(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory!,
          targetPlatform: _selectedTargetPlatform!,
          platform: _featureRequestPlatform,
          source: _featureRequestSource,
          appName: _featureRequestAppName,
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _titleController.clear();
      _descriptionController.clear();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedTargetPlatform = null;
        _selectedCategory = null;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Feature request sent successfully.')),
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
      appBar: AppBar(title: const Text('Feature Request')),
      resizeToAvoidBottomInset: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CommonEmailHeaderCard(
                title: 'Request a feature',
                subtitle:
                    'Share the improvement you want to see in the app next.',
                icon: Icons.lightbulb_outline_rounded,
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
              CommonEmailChoiceGroupField<FeatureRequestTargetPlatform>(
                title: 'Where should this feature be added?',
                subtitle: 'Select one option',
                value: _selectedTargetPlatform,
                onChanged: (value) {
                  setState(() {
                    _selectedTargetPlatform = value;
                  });
                },
                validator: (value) => CommonEmailValidators.selection(
                  value,
                  'Please choose where this feature should be added.',
                ),
                options: FeatureRequestTargetPlatform.values
                    .map(
                      (targetPlatform) =>
                          CommonEmailChoice<FeatureRequestTargetPlatform>(
                            value: targetPlatform,
                            label: targetPlatform.label,
                          ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              CommonEmailChoiceGroupField<FeatureRequestCategory>(
                title: 'Feature Type',
                subtitle: 'Select a category',
                value: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) => CommonEmailValidators.selection(
                  value,
                  'Please choose a feature category.',
                ),
                options: FeatureRequestCategory.values
                    .map(
                      (category) => CommonEmailChoice<FeatureRequestCategory>(
                        value: category,
                        label: category.label,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              CommonEmailSectionCard(
                child: Column(
                  children: [
                    CommonEmailTextField(
                      label: 'Feature Title',
                      hintText: 'Eg. Add quran bookmarking option',
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      validator: (value) => CommonEmailValidators.required(
                        value,
                        'a feature title',
                      ),
                    ),
                    const SizedBox(height: 16),
                    CommonEmailTextField(
                      label: 'Description',
                      hintText: 'Explain your idea in detail',
                      controller: _descriptionController,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 5,
                      maxLines: 7,
                      validator: (value) => CommonEmailValidators.required(
                        value,
                        'a description',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CommonEmailSubmitButton(
                key: const ValueKey('feature-request-submit-button'),
                label: 'Send Request',
                isSubmitting: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              Text(
                'We review all requests and may reach out for more details.',
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
