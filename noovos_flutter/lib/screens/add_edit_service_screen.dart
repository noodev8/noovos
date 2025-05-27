/*
Add/Edit Service Screen
This screen allows business owners and staff to add new services or edit existing ones
Features:
- Form validation for all required fields
- Category selection from dropdown
- Price and duration input with validation
- Buffer time configuration
- Description with character limit
*/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/app_styles.dart';
import '../api/create_service_api.dart';
import '../api/update_service_api.dart';
import '../api/get_categories_api.dart';
import '../api/upload_image_api.dart';
import '../api/delete_image_api.dart';
import '../helpers/image_picker_helper.dart';
import '../helpers/auth_helper.dart';
import '../helpers/cloudinary_helper.dart';

class AddEditServiceScreen extends StatefulWidget {
  final Map<String, dynamic> business;
  final bool isEditing;
  final Map<String, dynamic>? service;

  const AddEditServiceScreen({
    Key? key,
    required this.business,
    required this.isEditing,
    this.service,
  }) : super(key: key);

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _bufferTimeController = TextEditingController();

  List<dynamic> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  // Image upload related variables
  File? _selectedImage;
  String? _uploadedImageName;
  bool _isUploadingImage = false;

  // Existing image information for editing
  String? _existingImageName;

  // Track if there are unsaved changes
  bool _hasUnsavedChanges = false;

  // Track if image was just uploaded (to show success message)
  bool _imageJustUploaded = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    // If editing, populate the form with existing service data
    if (widget.isEditing && widget.service != null) {
      _populateFormWithServiceData();
    }
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _bufferTimeController.dispose();
    super.dispose();
  }

  // Load categories for the dropdown
  Future<void> _loadCategories() async {
    try {
      final result = await GetCategoriesApi.getCategories();

      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          if (result['success']) {
            _categories = result['data']['categories'] ?? [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  // Populate form with existing service data for editing
  void _populateFormWithServiceData() {
    final service = widget.service!;

    _serviceNameController.text = service['service_name'] ?? '';
    _descriptionController.text = service['description'] ?? '';

    // Handle price conversion
    final price = service['price'];
    if (price != null) {
      if (price is String) {
        _priceController.text = price;
      } else {
        _priceController.text = price.toString();
      }
    }

    // Handle duration conversion
    final duration = service['duration'];
    if (duration != null) {
      _durationController.text = duration.toString();
    }

    // Handle buffer time conversion
    final bufferTime = service['buffer_time'];
    if (bufferTime != null && bufferTime != 0) {
      _bufferTimeController.text = bufferTime.toString();
    }

    // Set selected category
    _selectedCategoryId = service['category_id'];

    // Load existing image information if available
    final imageName = service['image_name'];
    if (imageName != null && imageName.toString().isNotEmpty) {
      _existingImageName = imageName.toString();
      // Set uploaded image name to existing image so it doesn't get overwritten unless user selects new image
      _uploadedImageName = _existingImageName;
    }
  }

  // Save the service (create or update)
  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (widget.isEditing) {
        // Update existing service
        result = await UpdateServiceApi.updateService(
          serviceId: widget.service!['id'],
          serviceName: _serviceNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          duration: int.parse(_durationController.text),
          price: double.parse(_priceController.text),
          bufferTime: _bufferTimeController.text.isEmpty
              ? 0
              : int.parse(_bufferTimeController.text),
          categoryId: _selectedCategoryId,
          imageName: _uploadedImageName,
        );
      } else {
        // Create new service
        result = await CreateServiceApi.createService(
          businessId: widget.business['id'],
          serviceName: _serviceNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          duration: int.parse(_durationController.text),
          price: double.parse(_priceController.text),
          bufferTime: _bufferTimeController.text.isEmpty
              ? 0
              : int.parse(_bufferTimeController.text),
          categoryId: _selectedCategoryId,
          imageName: _uploadedImageName,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Clear unsaved changes flag
          _hasUnsavedChanges = false;
          // Clear upload success flag
          _imageJustUploaded = false;

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ??
                  (widget.isEditing ? 'Service updated successfully' : 'Service created successfully')),
              backgroundColor: AppStyles.successColor,
            ),
          );

          // Return to previous screen
          Navigator.of(context).pop();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to save service'),
              backgroundColor: AppStyles.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
    }
  }

  // Show warning dialog for unsaved changes
  Future<bool> _showUnsavedChangesDialog() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave without saving?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Clean up orphaned image if user uploaded but didn't save
              await _cleanupOrphanedImage();
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Clean up orphaned image when leaving without saving
  Future<void> _cleanupOrphanedImage() async {
    // Only clean up if we have a newly uploaded image that wasn't saved
    if (_uploadedImageName != null && _hasUnsavedChanges) {
      try {
        // Check if this is a new image (not the original existing image)
        final originalImageName = widget.service?['image_name'];
        final isNewImage = widget.service == null ||
                          originalImageName != _uploadedImageName;

        if (isNewImage) {
          // Delete the orphaned image from Cloudinary
          await DeleteImageApi.deleteImage(_uploadedImageName!);
          // Silently handle cleanup - don't show errors to user
        }
      } catch (e) {
        // Don't block navigation if cleanup fails
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _showUnsavedChangesDialog();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Service' : 'Add Service'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Save button in app bar
          if (!_isLoading)
            TextButton(
              onPressed: _saveService,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Service Name
                    TextFormField(
                      controller: _serviceNameController,
                      decoration: AppStyles.inputDecoration(
                        'Service Name *',
                        hint: 'e.g., Hair Cut, Massage, Consultation',
                        prefixIcon: const Icon(Icons.business_center),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Service name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Service name must be at least 2 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: AppStyles.inputDecoration(
                        'Description',
                        hint: 'Describe your service (optional)',
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      validator: (value) {
                        if (value != null && value.length > 500) {
                          return 'Description cannot exceed 500 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Price and Duration Row
                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: AppStyles.inputDecoration(
                              'Price (£) *',
                              hint: '25.00',
                              prefixIcon: const Icon(Icons.attach_money),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Price is required';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price < 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Duration
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: AppStyles.inputDecoration(
                              'Duration (min) *',
                              hint: '60',
                              prefixIcon: const Icon(Icons.schedule),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Duration is required';
                              }
                              final duration = int.tryParse(value);
                              if (duration == null || duration <= 0) {
                                return 'Enter a valid duration';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Buffer Time and Category Row
                    Row(
                      children: [
                        // Buffer Time
                        Expanded(
                          child: TextFormField(
                            controller: _bufferTimeController,
                            decoration: AppStyles.inputDecoration(
                              'Buffer Time (min)',
                              hint: '15',
                              prefixIcon: const Icon(Icons.timer),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final bufferTime = int.tryParse(value);
                                if (bufferTime == null || bufferTime < 0) {
                                  return 'Enter a valid buffer time';
                                }
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Category Dropdown
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedCategoryId,
                            isExpanded: true,
                            decoration: AppStyles.inputDecoration(
                              'Category',
                              prefixIcon: const Icon(Icons.category),
                            ),
                            hint: const Text('Select category'),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('No category'),
                              ),
                              ..._categories.map<DropdownMenuItem<int>>((category) {
                                return DropdownMenuItem<int>(
                                  value: category['id'],
                                  child: Text(
                                    category['name'],
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Service Image Section
                    _buildImageSection(),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveService,
                        style: AppStyles.primaryButtonStyle,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(widget.isEditing ? 'Update Service' : 'Create Service'),
                      ),
                    ),


                  ],
                ),
              ),
            ),
      ),
    );
  }

  // Build the image upload section
  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'Service Image',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_isUploadingImage)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Image preview or placeholder
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: _buildImagePreview(),
            ),

            const SizedBox(height: 12),

            // Upload buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingImage ? null : _selectAndUploadImage,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text(_getUploadButtonText()),
                  ),
                ),
                if (_hasAnyImage()) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _isUploadingImage ? null : _removeImage,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ],
            ),

            if (_imageJustUploaded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '✓ Image uploaded successfully',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to check if any image is available (selected or existing)
  bool _hasAnyImage() {
    return _selectedImage != null || (_existingImageName != null && _existingImageName!.isNotEmpty);
  }

  // Helper method to get appropriate button text
  String _getUploadButtonText() {
    if (_selectedImage != null) {
      return 'Change Image';
    } else if (_existingImageName != null && _existingImageName!.isNotEmpty) {
      return 'Replace Image';
    } else {
      return 'Add Image';
    }
  }

  // Build image preview widget
  Widget _buildImagePreview() {
    // Priority: 1. Selected new image, 2. Existing image from server, 3. Placeholder
    if (_selectedImage != null) {
      // Show newly selected image file
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
        ),
      );
    } else if (_existingImageName != null && _existingImageName!.isNotEmpty) {
      // Always treat as Cloudinary image - construct URL
      final cloudinaryUrl = CloudinaryHelper.getCloudinaryUrl(_existingImageName);

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          cloudinaryUrl,
          fit: BoxFit.cover,
          // Add cache-busting to prevent showing old cached images
          headers: {
            'Cache-Control': 'no-cache',
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'URL: $cloudinaryUrl',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      );
    } else {
      // Show placeholder when no image is available
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'No image selected',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }
  }

  // Select and upload image
  Future<void> _selectAndUploadImage() async {
    try {
      // Select image
      final imageFile = await ImagePickerHelper.showImageSourceDialog(context);

      if (imageFile != null && mounted) {
        setState(() {
          _selectedImage = imageFile;
          _isUploadingImage = true;
        });

        // Upload image to Cloudinary
        final result = await UploadImageApi.uploadImage(
          imageFile,
          folder: 'noovos',
        );

        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });

          if (result['success']) {
            setState(() {
              // Store only the filename in database, not the full URL
              _uploadedImageName = result['image_name'];
              // Update existing image name so UI shows new image immediately
              _existingImageName = result['image_name'];
              // Clear selected image since it's now uploaded
              _selectedImage = null;
              // Mark as having unsaved changes
              _hasUnsavedChanges = true;
              // Show success message for this upload
              _imageJustUploaded = true;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploaded successfully. Don\'t forget to save!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          } else {
            // Check if it's a token expiration error
            if (AuthHelper.isTokenExpired(result)) {
              await AuthHelper.handleTokenExpiration(context);
              return;
            }

            setState(() {
              _selectedImage = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: ${result['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _selectedImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove selected image
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageName = null;
      // Clear existing image information to indicate removal
      _existingImageName = null;
      // Mark as having unsaved changes
      _hasUnsavedChanges = true;
      // Clear upload success flag
      _imageJustUploaded = false;
    });
  }
}